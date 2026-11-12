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
// Week 11: the repository now owns the cache (stale-while-revalidate) and
// pagination, so the provider stays a thin adapter — no business rules leak
// here. A use case would only become mandatory if multi-source sync appeared.
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref
      .watch(announcementRepositoryProvider)
      .fetchAnnouncements();
  final failure = result.failure;
  if (failure != null) throw Exception(failure.message);
  return result.announcements;
});

// ---- Week 11: paginated infinite-scroll state. ----

/// Immutable state for the paginated announcement list.
class AnnouncementPageState {
  const AnnouncementPageState({
    this.items = const <Announcement>[],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Announcement> items;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  AnnouncementPageState copyWith({
    List<Announcement>? items,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return AnnouncementPageState(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final announcementPageProvider =
    NotifierProvider<AnnouncementPageNotifier, AnnouncementPageState>(
      AnnouncementPageNotifier.new,
    );

class AnnouncementPageNotifier extends Notifier<AnnouncementPageState> {
  var _page = 0;

  @override
  AnnouncementPageState build() => const AnnouncementPageState();

  /// Loads the next page. Safe to call repeatedly: concurrent calls are
  /// ignored while a request is in flight or when the end is reached.
  ///
  /// Optimisation rationale (docs/performance-report.md): the list appends
  /// only the new slice instead of rebuilding the full dataset, so scroll
  /// frame time stays flat as the list grows.
  Future<void> loadMore() async {
    final current = state;
    if (current.isLoadingMore || !current.hasMore) return;

    state = current.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = _page + 1;

    final result = await ref
        .read(announcementRepositoryProvider)
        .fetchPage(nextPage);

    if (result.failure != null) {
      state = state.copyWith(
        isLoadingMore: false,
        error: result.failure!.message,
      );
      return;
    }

    _page = nextPage;
    final fetched = result.announcements;
    state = state.copyWith(
      items: [...state.items, ...fetched],
      isLoadingMore: false,
      hasMore: fetched.isNotEmpty,
    );
  }

  /// Refreshes from page 1. Used by pull-to-refresh.
  Future<void> refresh() async {
    _page = 0;
    state = const AnnouncementPageState();
    await loadMore();
  }
}

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
final filteredAnnouncementsProvider = Provider<AsyncValue<List<Announcement>>>(
  (ref) {
    final query = ref.watch(searchQueryProvider);
    return ref
        .watch(announcementsProvider)
        .whenData((items) => filterAnnouncements(items, query));
  },
);

/// Week 11: search over the *paginated* list. Kept separate from
/// [filteredAnnouncementsProvider] so the infinite-scroll page and the search
/// box never fight over one state object.
final filteredPageProvider = Provider<List<Announcement>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final page = ref.watch(announcementPageProvider);
  return filterAnnouncements(page.items, query);
});
