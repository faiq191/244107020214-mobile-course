// Widget tests for the Week 10 chat feature.
//
// The repository is faked so no network and no API key are required. The real
// notifier, prompt builder, fallback and UI run unmocked.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/ai/domain/repositories/ai_repository.dart';
import 'package:campus_notify/features/ai/presentation/pages/ai_chat_page.dart';
import 'package:campus_notify/features/ai/presentation/providers/ai_providers.dart';

class _FakeAiRepository implements AiRepository {
  _FakeAiRepository({this.failing = false, this.streamTimesOut = false});

  bool failing;
  final bool streamTimesOut;

  @override
  Stream<String> streamAnswer({
    required String systemPrompt,
    required String userPrompt,
  }) async* {
    if (streamTimesOut) {
      throw const AiRequestException(
        'The AI request timed out. Check your network.',
        retryable: true,
      );
    }
    if (failing) {
      throw const AiRequestException('AI service busy.');
    }
    yield 'The midterm is on Monday at 08.00 WIB. ';
    yield 'Check the portal for your room.';
  }

  @override
  Future<({String? reply, Failure? failure})> ask({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (failing) {
      return (reply: null, failure: const NetworkFailure('AI service busy.'));
    }
    return (reply: 'The midterm is on Monday.', failure: null);
  }

  @override
  Future<bool> hasApiKey() async => true;

  @override
  Future<void> saveApiKey(String apiKey) async {}

  @override
  Future<void> clearApiKey() async {}
}

Widget _wrap(_FakeAiRepository repository, {bool hasKey = true}) {
  return ProviderScope(
    overrides: [
      aiRepositoryProvider.overrideWithValue(repository),
      aiKeyConfiguredProvider.overrideWith((ref) async => hasKey),
      aiContextProvider.overrideWithValue(
        'Midterm schedule posted — Monday, 08.00 WIB\n'
        'Library extended hours — open until 2 AM',
      ),
    ],
    child: const MaterialApp(home: AiChatPage()),
  );
}

void main() {
  testWidgets('streams an answer into the assistant bubble', (tester) async {
    await tester.pumpWidget(_wrap(_FakeAiRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('ai_chat_input')),
      'When is the midterm?',
    );
    await tester.tap(find.byKey(const Key('ai_chat_send')));
    await tester.pumpAndSettle();

    expect(find.text('When is the midterm?'), findsOneWidget);
    expect(
      find.text(
        'The midterm is on Monday at 08.00 WIB. '
        'Check the portal for your room.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the offline fallback and retries successfully', (
    tester,
  ) async {
    final repository = _FakeAiRepository(failing: true);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('ai_chat_input')), 'midterm');
    await tester.tap(find.byKey(const Key('ai_chat_send')));
    await tester.pumpAndSettle();

    expect(find.text('Offline fallback'), findsOneWidget);
    expect(find.textContaining('Offline results'), findsOneWidget);
    expect(find.byKey(const Key('ai_retry')), findsOneWidget);

    repository.failing = false;
    await tester.tap(find.byKey(const Key('ai_retry')));
    await tester.pumpAndSettle();

    expect(find.text('Offline fallback'), findsNothing);
    expect(find.textContaining('The midterm is on Monday'), findsOneWidget);
  });

  testWidgets('shows the missing-key banner when no key is configured', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeAiRepository(), hasKey: false));
    await tester.pumpAndSettle();

    expect(find.textContaining('No AI API key set'), findsOneWidget);
  });

  testWidgets('retries through the non-streaming endpoint on an SSE timeout', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeAiRepository(streamTimesOut: true)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('ai_chat_input')),
      'When is the midterm?',
    );
    await tester.tap(find.byKey(const Key('ai_chat_send')));
    await tester.pumpAndSettle();

    expect(find.text('The midterm is on Monday.'), findsOneWidget);
    expect(find.text('Offline fallback'), findsNothing);
  });
}
