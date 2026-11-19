import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/announcement.dart';
import '../providers/announcement_providers.dart';

/// Week 11 optimisation: the detail page reads from the paginated list first
/// (already in memory) and only falls back to the repository-backed provider
/// when the row is not part of the loaded page.
///
/// `ref.watch(...select(...))` keeps the page from rebuilding on every message
/// or unrelated announcement change — only the row matching [id] matters.
class AnnouncementDetailPage extends ConsumerWidget {
  const AnnouncementDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `select` narrows the rebuild scope: the page only rebuilds when the
    // specific announcement identified by [id] changes (codelab §4.2.D).
    final item = ref.watch(
      announcementPageProvider.select(
        (page) => page.items.cast<Announcement?>().firstWhere(
          (a) => a?.id == id,
          orElse: () => null,
        ),
      ),
    );

    // Not in the loaded page (deep link / cold start): use the full provider.
    final fallback = item == null
        ? ref
              .watch(announcementsProvider)
              .value
              ?.firstWhere(
                (a) => a.id == id,
                orElse: () => const Announcement(
                  id: '?',
                  title: 'Announcement',
                  preview: 'Details unavailable.',
                ),
              )
        : null;

    final resolved =
        item ??
        fallback ??
        const Announcement(
          id: '?',
          title: 'Announcement',
          preview: 'Details unavailable.',
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Announcement')),
      body: RepaintBoundary(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resolved.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(resolved.preview),
              const SizedBox(height: 24),
              Text(
                'Announcement #$id — the full body will be loaded from the '
                'Dio api_client once the real backend is connected.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
