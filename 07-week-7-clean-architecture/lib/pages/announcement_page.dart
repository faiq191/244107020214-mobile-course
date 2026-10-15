import 'package:flutter/material.dart';

import 'home_page.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final item = mockAnnouncements.firstWhere(
      (a) => a.id == id,
      orElse: () => const AnnouncementSummary(
        id: '?',
        title: 'Announcement',
        preview: 'Details unavailable.',
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
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
      ),
    );
  }
}
