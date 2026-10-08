import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../routes.dart';

class AnnouncementSummary {
  const AnnouncementSummary({
    required this.id,
    required this.title,
    required this.preview,
  });

  final String id;
  final String title;
  final String preview;
}

/// Mock data — swap for a repository backed by the Dio api_client in a
/// later lab.
const mockAnnouncements = [
  AnnouncementSummary(
    id: '1',
    title: 'Midterm schedule posted',
    preview: 'The midterm exam timetable is now available in the portal.',
  ),
  AnnouncementSummary(
    id: '2',
    title: 'Library extended hours',
    preview: 'The main library will stay open until 2 AM during finals week.',
  ),
  AnnouncementSummary(
    id: '3',
    title: 'Campus shuttle route change',
    preview: 'Route B is detoured via the stadium until further notice.',
  ),
];

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Token debug (masked)',
            icon: const Icon(Icons.key),
            onPressed: () => context.go(Routes.tokenDebug),
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
      body: ListView.separated(
        itemCount: mockAnnouncements.length,

        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = mockAnnouncements[index];
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
    );
  }
}
