// Week 12 — Lab step 3: "Test a dependency".
//
// The announcement page depends on the `AnnouncementRepository` CONTRACT, not
// on the real implementation. This test swaps in a `FakeAnnouncementRepository`
// so success and failure are both exercised without any network or storage
// (codelab §4). It also proves the notifier validates the title BEFORE touching
// the repository: an invalid title must never reach the fake.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcement/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcement/presentation/providers/announcement_providers.dart';

/// Fake implementing the DOMAIN interface — no Dio, no cache, no Firebase.
///
/// Behaviour is controlled by the test: pass [failOnAdd] to simulate a backend
/// error, and read [addCalls] to count how many times the repository was hit.
class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.addResult, this.failOnAdd = false});

  final Announcement? addResult;
  final bool failOnAdd;

  final List<String> addCalls = [];

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements() async {
    return (announcements: const <Announcement>[], failure: null);
  }

  @override
  Future<({List<Announcement> announcements, Failure? failure})> fetchPage(
    int page,
  ) async {
    return (announcements: const <Announcement>[], failure: null);
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> addAnnouncement(
    String title,
  ) async {
    addCalls.add(title);
    if (failOnAdd) {
      return (
        announcement: null,
        failure: const NetworkFailure('Backend is unavailable'),
      );
    }
    return (
      announcement:
          addResult ?? Announcement(id: 'x1', title: title, preview: 'Created'),
      failure: null,
    );
  }
}

/// Builds a container with the repository contract overridden by a fake.
ProviderContainer _containerWith(FakeAnnouncementRepository fake) {
  final container = ProviderContainer(
    overrides: [announcementRepositoryProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('AnnouncementPageNotifier.addAnnouncement (fake repository)', () {
    test(
      'success: prepends the created announcement and returns true',
      () async {
        final fake = FakeAnnouncementRepository();
        final container = _containerWith(fake);

        final ok = await container
            .read(announcementPageProvider.notifier)
            .addAnnouncement('Read the material');

        expect(ok, isTrue);
        expect(fake.addCalls, ['Read the material']);
        final items = container.read(announcementPageProvider).items;
        expect(items, hasLength(1));
        expect(items.first.title, 'Read the material');
      },
    );

    test('error: surfaces the failure and returns false', () async {
      final fake = FakeAnnouncementRepository(failOnAdd: true);
      final container = _containerWith(fake);

      final ok = await container
          .read(announcementPageProvider.notifier)
          .addAnnouncement('Read the material');

      expect(ok, isFalse);
      expect(
        container.read(announcementPageProvider).error,
        'Backend is unavailable',
      );
      // The row is NOT added when the repository fails.
      expect(container.read(announcementPageProvider).items, isEmpty);
    });

    test('invalid title never reaches the repository', () async {
      final fake = FakeAnnouncementRepository();
      final container = _containerWith(fake);

      final ok = await container
          .read(announcementPageProvider.notifier)
          .addAnnouncement('   ');

      expect(ok, isFalse);
      expect(fake.addCalls, isEmpty);
    });
  });
}
