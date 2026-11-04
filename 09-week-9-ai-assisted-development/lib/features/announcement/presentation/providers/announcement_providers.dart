import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/filter_announcements.dart';

// Data layer.
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(),
);

// Presentation layer.
//
// AI Challenge decision — NO use case here: fetchAnnouncements is a
// single one-line CRUD call with zero business rules (no validation,
// sorting, or multi-repository combination). Repository -> provider
// directly; a GetAnnouncements use case would be pure over-engineering.
// A use case becomes mandatory the moment caching/sync logic appears.
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref
      .watch(announcementRepositoryProvider)
      .fetchAnnouncements();
  final failure = result.failure;
  if (failure != null) throw Exception(failure.message);
  return result.announcements;
});

// ---- Week 9 / Lab 2: search feature wiring. ----

// UI state only: the raw query typed by the user. No business rule lives
// here, so this stays a plain Notifier in the presentation layer.
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

// Derived state: the fetched list passed through the pure domain use case
// `filterAnnouncements`. The widget never filters by itself —
// widget (UI) -> provider (state) -> use case (rules) -> repository.
final filteredAnnouncementsProvider = Provider<AsyncValue<List<Announcement>>>((
  ref,
) {
  final query = ref.watch(searchQueryProvider);
  return ref
      .watch(announcementsProvider)
      .whenData((items) => filterAnnouncements(items, query));
});
