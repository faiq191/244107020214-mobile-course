// Generates the Week 9 screenshot evidence with real Roboto text instead of
// the default Ahem test font (which would render every glyph as a black box).
//
// Run once to (re)create the PNGs:
//   flutter test test/screenshots_test.dart --update-goldens
// Afterwards the same test verifies the committed files:
//   flutter test test/screenshots_test.dart
import 'dart:io';

import 'package:campus_notify/features/announcement/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcement/presentation/pages/home_page.dart';
import 'package:campus_notify/features/announcement/presentation/providers/announcement_providers.dart';
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

void main() {
  setUpAll(() async {
    await _loadFont('Roboto', [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
    ]);
    await _loadFont('MaterialIcons', ['materialicons-regular.otf']);
  });

  final fixtures = [
    const Announcement(
      id: 'a1',
      title: 'Ujian Algoritma',
      preview: 'Ruang 204, pukul 08.00 WIB',
    ),
    const Announcement(
      id: 'a2',
      title: 'Groceries Sale at Kantin',
      preview: 'Diskon 20% setiap Jumat',
    ),
    const Announcement(
      id: 'a3',
      title: 'Beasiswa Dalam Negeri 2026',
      preview: 'Pendaftaran dibuka 1 Juni',
    ),
    const Announcement(
      id: 'a4',
      title: 'Midterm Schedule',
      preview: 'Jadwal ujian tengah semester sudah terbit',
    ),
  ];

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          announcementsProvider.overrideWith((ref) => Future.value(fixtures)),
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

  testWidgets('home initial list', (tester) async {
    await pumpHome(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/home-initial.png'),
    );
  });

  testWidgets('home filtered by midterm', (tester) async {
    await pumpHome(tester);
    await tester.enterText(
      find.byKey(const Key('home_search_field')),
      'midterm',
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/home-filtered.png'),
    );
  });

  testWidgets('home empty state for unmatched query', (tester) async {
    await pumpHome(tester);
    await tester.enterText(
      find.byKey(const Key('home_search_field')),
      'zzz-missing',
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/home-empty.png'),
    );
  });
}
