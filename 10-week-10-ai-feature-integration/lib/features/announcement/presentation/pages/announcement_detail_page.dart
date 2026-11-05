import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/announcement.dart';
import '../providers/announcement_providers.dart';

class AnnouncementDetailPage extends ConsumerWidget {
  const AnnouncementDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcement')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          final item = items.firstWhere(
            (a) => a.id == id,
            orElse: () => const Announcement(
              id: '?',
              title: 'Announcement',
              preview: 'Details unavailable.',
            ),
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(item.preview),
                const SizedBox(height: 24),
                Text(
                  'Announcement #$id — the full body will be loaded from the '
                  'Dio api_client once the real backend is connected.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
