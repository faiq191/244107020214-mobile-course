// Generates the Week 10 screenshot evidence with real Roboto text instead of
// the default Ahem test font (which would render every glyph as a black box).
//
// Run once to (re)create the PNGs:
//   flutter test test/screenshots_test.dart --update-goldens
// Afterwards the same test verifies the committed files:
//   flutter test test/screenshots_test.dart
import 'dart:io';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/ai/domain/repositories/ai_repository.dart';
import 'package:campus_notify/features/ai/presentation/pages/ai_chat_page.dart';
import 'package:campus_notify/features/ai/presentation/providers/ai_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _fontDir = 'D:/Flutter/flutter/bin/cache/artifacts/material_fonts';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final name in files) {
    final bytes = File('$_fontDir/$name').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

class _FakeAiRepository implements AiRepository {
  _FakeAiRepository({this.failing = false});

  final bool failing;

  @override
  Stream<String> streamAnswer({
    required String systemPrompt,
    required String userPrompt,
  }) async* {
    if (failing) throw const AiRequestException('AI service busy.');
    yield 'The midterm is scheduled for Monday at 08.00 WIB. ';
    yield 'Open the campus portal to confirm your room.';
  }

  @override
  Future<({String? reply, Failure? failure})> ask({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (failing) {
      return (reply: null, failure: const NetworkFailure('AI service busy.'));
    }
    return (
      reply: 'The midterm is scheduled for Monday at 08.00 WIB.',
      failure: null,
    );
  }

  @override
  Future<bool> hasApiKey() async => true;

  @override
  Future<void> saveApiKey(String apiKey) async {}

  @override
  Future<void> clearApiKey() async {}
}

void main() {
  setUpAll(() async {
    await _loadFont('Roboto', [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
    ]);
    await _loadFont('MaterialIcons', ['materialicons-regular.otf']);
  });

  Future<void> pumpChat(WidgetTester tester, {required bool failing}) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiRepositoryProvider.overrideWithValue(
            _FakeAiRepository(failing: failing),
          ),
          aiKeyConfiguredProvider.overrideWith((ref) async => true),
          aiContextProvider.overrideWithValue(
            'Midterm schedule posted — Monday, 08.00 WIB\n'
            'Library extended hours — open until 2 AM\n'
            'Campus shuttle route change — Route B detour',
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
          home: const AiChatPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ai chat initial', (tester) async {
    await pumpChat(tester, failing: false);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/ai-chat-initial.png'),
    );
  });

  testWidgets('ai chat conversation', (tester) async {
    await pumpChat(tester, failing: false);
    await tester.enterText(
      find.byKey(const Key('ai_chat_input')),
      'When is the midterm?',
    );
    await tester.tap(find.byKey(const Key('ai_chat_send')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/ai-chat-conversation.png'),
    );
  });

  testWidgets('ai chat offline fallback', (tester) async {
    await pumpChat(tester, failing: true);
    await tester.enterText(find.byKey(const Key('ai_chat_input')), 'midterm');
    await tester.tap(find.byKey(const Key('ai_chat_send')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/ai-chat-fallback.png'),
    );
  });

  testWidgets('ai chat api key dialog', (tester) async {
    await pumpChat(tester, failing: false);
    await tester.tap(find.byKey(const Key('ai_settings_key')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/ai-chat-key-dialog.png'),
    );
  });
}
