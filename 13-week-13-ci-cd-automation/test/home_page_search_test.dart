// Widget tests for the HomePage: it must render the paginated list and show an
// explicit empty state when the search query matches nothing.
//
// Only the data source (announcementPageProvider) is overridden with fixture
// data; searchQueryProvider, filteredPageProvider and the real domain use case
// `filterAnnouncements` run unmocked, so these tests also cover the UI <->
// provider wiring end to end.
//
// Note: the helper builds the override list inline because Riverpod 3 no
// longer exports the `Override` type.
import 'package:campus_notify/features/announcement/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcement/presentation/pages/home_page.dart';
import 'package:campus_notify/features/announcement/presentation/providers/announcement_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixturePageNotifier extends AnnouncementPageNotifier {
  _FixturePageNotifier(this.fixtures);

  final List<Announcement> fixtures;

  @override
  AnnouncementPageState build() =>
      AnnouncementPageState(items: fixtures, hasMore: false);

  @override
  Future<void> loadMore() async {}
}

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
      announcementPageProvider.overrideWith(
        () => _FixturePageNotifier(fixtures),
      ),
    ],
    child: const MaterialApp(home: HomePage()),
  );

  testWidgets('shows the empty state when the query matches nothing', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text('Wireless mesh seminar'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('home_search_field')),
      'zzz-no-match',
    );
    await tester.pumpAndSettle();

    expect(find.text('No announcements found'), findsOneWidget);
    expect(find.text('Wireless mesh seminar'), findsNothing);
  });

  testWidgets('filters by title and clearing the query restores the list', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('home_search_field')),
      'midterm',
    );
    await tester.pumpAndSettle();
    expect(find.text('Midterm schedule'), findsOneWidget);
    expect(find.text('Wireless mesh seminar'), findsNothing);

    await tester.enterText(find.byKey(const Key('home_search_field')), '');
    await tester.pumpAndSettle();
    expect(find.text('Midterm schedule'), findsOneWidget);
    expect(find.text('Wireless mesh seminar'), findsOneWidget);
  });
}
