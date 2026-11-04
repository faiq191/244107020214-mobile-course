// Widget tests for the Lab 3 refactor: HomePage is UI-only and must show an
// explicit empty state when the search query matches nothing.
//
// Only the data source (announcementsProvider) is overridden with fixture
// data; searchQueryProvider, filteredAnnouncementsProvider and the real
// domain use case `filterAnnouncements` run unmocked, so these tests also
// cover the UI <-> provider wiring end to end.
//
// Note: the helper takes no parameters because Riverpod 3 no longer exports
// the `Override` type (first verification run failed with
// 'Override' isn't a type), so the override list is built inline.
import 'package:campus_notify/features/announcement/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcement/presentation/pages/home_page.dart';
import 'package:campus_notify/features/announcement/presentation/providers/announcement_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixtures = [
    Announcement(
      id: 'a1',
      title: 'Wireless mesh seminar',
      preview: 'Friday, hall A',
    ),
    Announcement(
      id: 'a2',
      title: 'Midterm schedule',
      preview: 'Published today',
    ),
  ];

  Widget wrap() => ProviderScope(
    overrides: [
      announcementsProvider.overrideWith((ref) => Future.value(fixtures)),
    ],
    child: const MaterialApp(home: HomePage()),
  );

  testWidgets('shows the empty state when the query matches nothing', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text('Wireless mesh seminar'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz-no-match');
    await tester.pumpAndSettle();

    expect(find.text('No announcements found'), findsOneWidget);
    expect(find.text('Wireless mesh seminar'), findsNothing);
  });

  testWidgets('filters by title and clearing the query restores the list', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'midterm');
    await tester.pumpAndSettle();
    expect(find.text('Midterm schedule'), findsOneWidget);
    expect(find.text('Wireless mesh seminar'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Midterm schedule'), findsOneWidget);
    expect(find.text('Wireless mesh seminar'), findsOneWidget);
  });
}
