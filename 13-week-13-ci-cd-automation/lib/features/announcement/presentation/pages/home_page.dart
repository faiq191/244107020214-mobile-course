import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/usecases/validate_announcement_title.dart';
import '../providers/announcement_providers.dart';

/// Lab 3 result: after the refactor this page is UI-only.
///
/// Week 11 performance work (see docs/performance-report.md):
/// - the list is driven by [announcementPageProvider] with infinite scroll
///   instead of materialising the whole dataset in one ListView;
/// - each row is its own widget class ([_AnnouncementTile]) so a parent
///   rebuild does not rebuild the tiles whose data did not change;
/// - the search box is wrapped in a [RepaintBoundary] so typing repaints only
///   the field, not the scrolling list;
/// - the search result is derived through [filteredPageProvider], which keeps
///   the filtering rule in the pure domain use case `filterAnnouncements`.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// One scroll controller for the whole page. It survives search-box
  /// rebuilds, so the position stays stable while the user types.
  final _scroll = ScrollController();

  /// Week 12: controller for the "new announcement" field. Kept in state so
  /// widget and integration tests can drive it through a stable [Key].
  final _newTitle = TextEditingController();

  String? _titleError;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // First page after the first frame so the widget has a context.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(announcementPageProvider.notifier).loadMore();
    });
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _newTitle.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    // Prefetch 200 px before the end to hide the network latency behind the
    // remaining scroll distance (codelab §5.2).
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(announcementPageProvider.notifier).loadMore();
    }
  }

  /// Week 12: saves a new announcement through the notifier, which validates
  /// the title with the pure domain rule [isValidAnnouncementTitle].
  Future<void> _saveNewAnnouncement() async {
    final value = _newTitle.text;
    if (!isValidAnnouncementTitle(value)) {
      setState(() => _titleError = 'Title cannot be empty');
      return;
    }

    final added = await ref
        .read(announcementPageProvider.notifier)
        .addAnnouncement(value);

    if (!mounted) return;
    setState(() => _titleError = added ? null : 'Could not save the title');
    if (added) _newTitle.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('home_open_ai'),
        onPressed: () => context.go('/ai'),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Ask AI'),
      ),
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Token debug (masked)',
            icon: const Icon(Icons.key),
            onPressed: () => context.go('/debug/token'),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            // Clears tokens, invalidates authStateProvider; the router
            // redirect then bounces back to /login.
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // RepaintBoundary: typing repaints only this box, not the list.
          RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                key: const Key('home_search_field'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search announcements…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                // The widget never filters by itself; it only publishes the
                // raw query. filteredPageProvider derives the list.
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).update(value),
              ),
            ),
          ),
          // Week 12: the "add announcement" form. The widget only publishes
          // the title; validation and persistence live behind the notifier.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('announcement-title-field'),
                    controller: _newTitle,
                    decoration: InputDecoration(
                      hintText: 'New announcement title',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: _titleError,
                    ),
                    onSubmitted: (_) => _saveNewAnnouncement(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('save-announcement-button'),
                  onPressed: _saveNewAnnouncement,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          Expanded(child: _AnnouncementList(scroll: _scroll)),
        ],
      ),
    );
  }
}

/// The scrollable list. A separate `ConsumerWidget` keeps the header out of
/// the rebuild scope: only this subtree reacts to new pages / search changes.
class _AnnouncementList extends ConsumerWidget {
  const _AnnouncementList({required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredPageProvider);
    final page = ref.watch(announcementPageProvider);

    if (items.isEmpty && page.isLoadingMore) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty && page.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(page.error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  ref.read(announcementPageProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return const _EmptyState();
    }

    // `itemCount + 1` reserves the last slot for the loading indicator.
    final showLoader = page.hasMore || page.isLoadingMore;

    return RefreshIndicator(
      onRefresh: () => ref.read(announcementPageProvider.notifier).refresh(),
      child: ListView.builder(
        controller: scroll,
        // A stable key lets Flutter reuse element slots across rebuilds.
        // Week 12: widget/integration tests find the list through this key
        // (a PageStorageKey also preserves the scroll offset).
        key: const PageStorageKey<String>('announcement-list'),
        itemCount: items.length + (showLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _AnnouncementTile(item: items[index]);
        },
      ),
    );
  }
}

/// One row. Extracted into its own class so a list rebuild does not rebuild
/// the tiles whose data did not change (codelab §4.2.B).
class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(item.title),
          subtitle: Text(
            item.preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => context.go('/announcement/${item.id}'),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// Lab 3 requirement: an explicit empty state whenever the (filtered) list
/// has no rows - e.g. the search keyword matches nothing.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text('No announcements found'),
          const SizedBox(height: 4),
          Text(
            'Try a different search keyword.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
