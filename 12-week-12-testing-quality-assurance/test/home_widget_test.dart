// Week 12 — Lab step 4: "Test the UI".
//
// Widget tests render the real HomePage and drive it like a user would:
// enterText into the title field, tap the save button, then pumpAndSettle to
// let the notifier rebuild the list (codelab §5).
//
// Only the repository is faked — the providers, the pure domain rule and the
// widget wiring all run for real, so these tests also cover the
// UI <-> provider <-> use case path.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcement/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcement/presentation/pages/home_page.dart';
import 'package:campus_notify/features/announcement/presentation/providers/announcement_providers.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_providers.dart';

/// Fake repository that echoes added titles (and can simulate a failure).
class _FakeRepository implements AnnouncementRepository {
  _FakeRepository({this.failOnAdd = false});

  final bool failOnAdd;

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements() async =>
      (announcements: const <Announcement>[], failure: null);

  @override
  Future<({List<Announcement> announcements, Failure? failure})> fetchPage(
    int page,
  ) async => (announcements: const <Announcement>[], failure: null);

  @override
  Future<({Announcement? announcement, Failure? failure})> addAnnouncement(
    String title,
  ) async {
    if (failOnAdd) {
      return (
        announcement: null,
        failure: const NetworkFailure('Backend is unavailable'),
      );
    }
    return (
      announcement: Announcement(id: 'new', title: title, preview: 'Created'),
      failure: null,
    );
  }
}

class _SignedInAuth extends AuthNotifier {
  @override
  Future<bool> build() async => true;
}

/// A page notifier that starts with fixture rows instead of hitting the fake
/// network on the first frame, and delegates adds to the faked repository.
class _SeededNotifier extends AnnouncementPageNotifier {
  _SeededNotifier(this.rows);

  final List<Announcement> rows;

  @override
  AnnouncementPageState build() =>
      AnnouncementPageState(items: rows, hasMore: false);

  @override
  Future<void> loadMore() async {}
}

Widget _wrap({
  required AnnouncementRepository repository,
  List<Announcement> seed = const [],
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(_SignedInAuth.new),
      announcementRepositoryProvider.overrideWithValue(repository),
      announcementPageProvider.overrideWith(() => _SeededNotifier(seed)),
    ],
    child: const MaterialApp(home: HomePage()),
  );
}

void main() {
  const fixture = [
    Announcement(id: 'a1', title: 'Wireless mesh seminar', preview: 'Hall A'),
    Announcement(id: 'a2', title: 'Midterm schedule', preview: 'Today'),
  ];

  testWidgets('shows the initial list and the add form', (tester) async {
    await tester.pumpWidget(
      _wrap(repository: _FakeRepository(), seed: fixture),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wireless mesh seminar'), findsOneWidget);
    expect(find.text('Midterm schedule'), findsOneWidget);
    expect(find.byKey(const Key('announcement-title-field')), findsOneWidget);
    expect(find.byKey(const Key('save-announcement-button')), findsOneWidget);
  });

  testWidgets('shows a validation message for an empty title', (tester) async {
    await tester.pumpWidget(
      _wrap(repository: _FakeRepository(), seed: fixture),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-announcement-button')));
    await tester.pumpAndSettle();

    expect(find.text('Title cannot be empty'), findsOneWidget);
    // The list is untouched.
    expect(find.text('Wireless mesh seminar'), findsOneWidget);
  });

  testWidgets('adds a valid title and shows it in the list', (tester) async {
    await tester.pumpWidget(
      _wrap(repository: _FakeRepository(), seed: fixture),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('announcement-title-field')),
      'Read the material',
    );
    await tester.tap(find.byKey(const Key('save-announcement-button')));
    await tester.pumpAndSettle();

    expect(find.text('Read the material'), findsOneWidget);
  });

  testWidgets('surfaces a repository error without adding a row', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(repository: _FakeRepository(failOnAdd: true), seed: fixture),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('announcement-title-field')),
      'Read the material',
    );
    await tester.tap(find.byKey(const Key('save-announcement-button')));
    await tester.pumpAndSettle();

    expect(find.text('Could not save the title'), findsOneWidget);
    // The row is NOT added: the list still shows only the seed rows. The text
    // field keeps the typed value, so we assert on the tile count instead.
    expect(find.byType(ListTile), findsNWidgets(fixture.length));
  });
}
