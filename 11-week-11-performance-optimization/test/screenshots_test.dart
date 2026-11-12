// Generates the Week 11 screenshot evidence with real Roboto text instead of
// the default Ahem test font (which would render every glyph as a black box).
//
// The screenshots cover both the performance-lab evidence (baseline vs
// optimised list) and the Week 10 AI chat feature that Week 11 builds on.
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
import 'package:campus_notify/features/announcement/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcement/presentation/pages/home_page.dart';
import 'package:campus_notify/features/announcement/presentation/providers/announcement_providers.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_providers.dart';
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

/// Fixture list used for the paginated HomePage screenshots.
const _fixtureAnnouncements = <Announcement>[
  Announcement(
    id: '1',
    title: 'Midterm schedule posted',
    preview: 'The midterm exam timetable is now available in the portal.',
  ),
  Announcement(
    id: '2',
    title: 'Library extended hours',
    preview: 'The main library will stay open until 2 AM during finals week.',
  ),
  Announcement(
    id: '3',
    title: 'Campus shuttle route change',
    preview: 'Route B is detoured via the stadium until further notice.',
  ),
  Announcement(
    id: '4',
    title: 'Scholarship registration open',
    preview: 'Domestic scholarship applications open on 1 June.',
  ),
];

class _FixturePageNotifier extends AnnouncementPageNotifier {
  _FixturePageNotifier(this.fixtures);

  final List<Announcement> fixtures;

  @override
  AnnouncementPageState build() =>
      AnnouncementPageState(items: fixtures, hasMore: false);

  @override
  Future<void> loadMore() async {}
}

class _FixtureAuth extends AuthNotifier {
  @override
  Future<bool> build() async => true;
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

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_FixtureAuth.new),
          announcementPageProvider.overrideWith(
            () => _FixturePageNotifier(_fixtureAnnouncements),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('announcement list (after profile)', (tester) async {
    await pumpHome(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/after-profile-ui.png'),
    );
  });

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
