import 'package:dio/dio.dart';

import '../../../../core/failures.dart';
import '../../domain/repositories/ai_repository.dart';
import '../ai_api_client.dart';
import '../ai_key_store.dart';

/// Converts every data-layer error into one friendly, non-leaky message.
///
/// Raw provider JSON, stack traces and the API key are never shown in the UI
/// or written to logs. The fallback path in the notifier handles the UX.
Failure mapAiError(Object error) {
  if (error is AiRequestException) {
    return LocalFailure(error.message);
  }

  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) {
      return const AuthFailure(
        'The AI API key was rejected. Check it in the key dialog.',
      );
    }
    if (status == 400) {
      return const NetworkFailure(
        'The AI provider rejected the request. Check the key and model.',
      );
    }
    if (status == 404) {
      return const NetworkFailure(
        'The selected AI model is not available for this key.',
      );
    }
    if (status == 429) {
      return const NetworkFailure(
        'The AI is rate-limited right now. Please wait a minute.',
      );
    }
    if (status != null && status >= 500) {
      return const NetworkFailure(
        'The AI service is temporarily unavailable. Try again later.',
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure(
        'The AI request timed out. Check your network.',
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return const NetworkFailure('No internet connection to the AI service.');
    }
    if (status != null) {
      return NetworkFailure('The AI service returned HTTP $status.');
    }
    return const NetworkFailure('Could not reach the AI service.');
  }

  return const LocalFailure('The AI request failed.');
}

/// True when a retry through the non-streaming endpoint is worth attempting.
///
/// 401/403/400/404/429 mean retrying the same request immediately cannot help.
/// Timeouts, connection resets and 5xx are transient.
bool isRetryableAiError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status != null) return status >= 500;
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.unknown => true,
      _ => false,
    };
  }
  return false;
}

class AiRepositoryImpl implements AiRepository {
  factory AiRepositoryImpl({AiApiClient? client, AiKeyStore? keyStore}) {
    final store = keyStore ?? AiKeyStore();
    return AiRepositoryImpl._(client ?? AiApiClient(keyStore: store), store);
  }

  AiRepositoryImpl._(this._client, this._keyStore);

  final AiKeyStore _keyStore;
  final AiApiClient _client;

  @override
  Stream<String> streamAnswer({
    required String systemPrompt,
    required String userPrompt,
  }) async* {
    try {
      // Do not use `yield*` here: in an async* function an error from the
      // delegated stream bypasses this try/catch and reaches the caller raw.
      // That made every provider failure show the generic UI message instead
      // of the mapped 401/429/timeout message. `await for` keeps the mapping.
      await for (final chunk in _client.stream(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      )) {
        yield chunk;
      }
    } catch (e) {
      throw AiRequestException(
        mapAiError(e).message,
        retryable: e is AiRequestException
            ? e.retryable
            : isRetryableAiError(e),
      );
    }
  }

  @override
  Future<({String? reply, Failure? failure})> ask({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    try {
      final reply = await _client.ask(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
      return (reply: reply, failure: null);
    } catch (e) {
      return (reply: null, failure: mapAiError(e));
    }
  }

  @override
  Future<bool> hasApiKey() => _keyStore.hasKey();

  @override
  Future<void> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      throw const AiRequestException('The API key cannot be empty.');
    }
    await _keyStore.save(trimmed);
  }

  @override
  Future<void> clearApiKey() => _keyStore.clear();
}
