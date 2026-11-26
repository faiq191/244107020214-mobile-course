// Week 12 — Lab step 5: "Test the main flow".
//
// This is an integration test: it drives the REAL app widget tree (router,
// HomePage, providers and the domain rule) end to end, from "the user lands on
// the announcement list" to "the new row appears in the list". Only the two
// data-layer plugins are replaced (auth session + repository), because a real
// device plugin is outside the scope of the flow under test.
//
// Run it on a connected emulator or device:
//
//   flutter test integration_test/app_test.dart -d emulator-5554
//
// To run the full `main()` entry point instead, swap the `pumpWidget` block
// for:
//
//   app.main();
//   await tester.pumpAndSettle();
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcement/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcement/presentation/providers/announcement_providers.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_providers.dart';
import 'package:campus_notify/main.dart';

/// In-memory repository so the flow is deterministic and offline.
class _InMemoryRepository implements AnnouncementRepository {
  final List<Announcement> _rows = [
    const Announcement(
      id: 'a1',
      title: 'Wireless mesh seminar',
      preview: 'Friday, hall A',
    ),
  ];

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements() async => (announcements: _rows, failure: null);

  /// Only page 1 has data; later pages are empty so the notifier sets
  /// `hasMore: false`. Without that the list keeps a loading spinner alive and
  /// `pumpAndSettle` would never settle on a real device.
  @override
  Future<({List<Announcement> announcements, Failure? failure})> fetchPage(
    int page,
  ) async => page == 1
      ? (announcements: _rows, failure: null)
      : (announcements: const <Announcement>[], failure: null);

  @override
  Future<({Announcement? announcement, Failure? failure})> addAnnouncement(
    String title,
  ) async {
    final created = Announcement(
      id: 'n${_rows.length}',
      title: title,
      preview: 'Created',
    );
    _rows.insert(0, created);
    return (announcement: created, failure: null);
  }
}

class _SignedInAuth extends AuthNotifier {
  @override
  Future<bool> build() async => true;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a user can add an announcement and see it in the list', (
    tester,
  ) async {
    final repository = _InMemoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_SignedInAuth.new),
          announcementRepositoryProvider.overrideWithValue(repository),
        ],
        child: const CampusNotifyApp(),
      ),
    );
    // Let the first frame render, then let the post-frame `loadMore()` future
    // complete. Bounded pumps keep this deterministic on a real device where a
    // stray animation could stop `pumpAndSettle` from ever returning.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The signed-in user lands on the announcement list.
    expect(find.text('Campus Notify'), findsOneWidget);
    expect(find.text('Wireless mesh seminar'), findsOneWidget);

    // Add a task through the real form.
    await tester.enterText(
      find.byKey(const Key('announcement-title-field')),
      'Read the material',
    );
    await tester.tap(find.byKey(const Key('save-announcement-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Read the material'), findsOneWidget);
  });
}
