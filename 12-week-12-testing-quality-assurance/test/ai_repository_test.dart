// Guards the data -> domain error boundary.
//
// Regression: the first implementation used `yield*` inside `async*`; an
// error from the delegated SSE stream bypassed the surrounding try/catch, so
// the UI only ever saw the generic "AI request failed" message instead of the
// mapped 401/429/timeout message. These tests throw from a fake client and
// assert the mapped domain error.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/ai/data/ai_api_client.dart';
import 'package:campus_notify/features/ai/data/ai_key_store.dart';
import 'package:campus_notify/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:campus_notify/features/ai/domain/repositories/ai_repository.dart';

class _ThrowingClient extends AiApiClient {
  _ThrowingClient(this.error) : super(keyStore: AiKeyStore());

  final Object error;

  @override
  Stream<String> stream({
    required String systemPrompt,
    required String userPrompt,
  }) async* {
    throw error;
  }
}

AiRepositoryImpl _repositoryThrowing(Object error) {
  return AiRepositoryImpl(
    client: _ThrowingClient(error),
    keyStore: AiKeyStore(),
  );
}

DioException _dioError(int status) {
  final options = RequestOptions(path: '/models/test');
  return DioException(
    requestOptions: options,
    response: Response<dynamic>(requestOptions: options, statusCode: status),
    type: DioExceptionType.badResponse,
  );
}

Matcher _mappedError(String messagePart) {
  return isA<AiRequestException>().having(
    (e) => e.message,
    'message',
    contains(messagePart),
  );
}

void main() {
  test('maps 401 to the API-key message', () async {
    await expectLater(
      _repositoryThrowing(_dioError(401))
          .streamAnswer(systemPrompt: 's', userPrompt: 'u'),
      emitsError(_mappedError('API key was rejected')),
    );
  });

  test('maps 429 to the rate-limit message', () async {
    await expectLater(
      _repositoryThrowing(_dioError(429))
          .streamAnswer(systemPrompt: 's', userPrompt: 'u'),
      emitsError(_mappedError('rate-limited')),
    );
  });

  test('maps a timeout to the network message', () async {
    final error = DioException(
      requestOptions: RequestOptions(path: '/models/test'),
      type: DioExceptionType.connectionTimeout,
    );
    await expectLater(
      _repositoryThrowing(error)
          .streamAnswer(systemPrompt: 's', userPrompt: 'u'),
      emitsError(_mappedError('timed out')),
    );
  });

  test('maps an unknown failure without leaking the raw error', () async {
    await expectLater(
      _repositoryThrowing(StateError('secret internals'))
          .streamAnswer(systemPrompt: 's', userPrompt: 'u'),
      emitsError(
        isA<AiRequestException>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('AI request failed'),
            isNot(contains('secret internals')),
          ),
        ),
      ),
    );
  });

  test('flags only transient failures as retryable', () {
    expect(isRetryableAiError(_dioError(401)), isFalse);
    expect(isRetryableAiError(_dioError(404)), isFalse);
    expect(isRetryableAiError(_dioError(429)), isFalse);
    expect(isRetryableAiError(_dioError(503)), isTrue);
    expect(
      isRetryableAiError(
        DioException(
          requestOptions: RequestOptions(path: '/models/test'),
          type: DioExceptionType.receiveTimeout,
        ),
      ),
      isTrue,
    );
  });

  test('tries the next model only on 404 or 503', () {
    expect(AiApiClient.shouldTryNextModel(_dioError(404)), isTrue);
    expect(AiApiClient.shouldTryNextModel(_dioError(503)), isTrue);
    expect(AiApiClient.shouldTryNextModel(_dioError(400)), isFalse);
    expect(AiApiClient.shouldTryNextModel(_dioError(401)), isFalse);
    expect(AiApiClient.shouldTryNextModel(_dioError(429)), isFalse);
    expect(AiApiClient.shouldTryNextModel(StateError('boom')), isFalse);
  });
}
