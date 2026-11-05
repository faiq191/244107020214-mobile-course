import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/announcement_providers.dart';

/// Lab 3 result: after the refactor this page is UI-only.
///
/// It renders [filteredAnnouncementsProvider] (state + filtering live in the
/// provider layer) and forwards raw input to [searchQueryProvider]. The
/// search rule itself lives in the domain use case `filterAnnouncements`:
/// widget (UI) -> provider (state) -> use case (rules) -> repository.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filteredAnnouncementsProvider);

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              key: const Key('home_search_field'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search announcements…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              // The widget never filters by itself; it only publishes the raw
              // query. filteredAnnouncementsProvider derives the list.
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).update(value),
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$e'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(announcementsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(item.title),
                          subtitle: Text(
                            item.preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => context.go('/announcement/${item.id}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
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
