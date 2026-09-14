import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

// Menggunakan ConsumerWidget agar dapat mengakses WidgetRef secara langsung di build()
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch digunakan hanya di dalam build method untuk mendengarkan perubahan state
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Application Statistics')),
      // AsyncValue.when menangani ketiga state: loading, error, dan success (data)
      body: statsAsync.when(
        // 1. Loading state: Menampilkan spinner di tengah layar
        loading: () => const Center(child: CircularProgressIndicator()),
        // 2. Error state: Menampilkan pesan kesalahan dan tombol retry
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Failed to load stats: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  // Pada callback button, gunakan ref.invalidate untuk memicu build() ulang
                  onPressed: () => ref.invalidate(statsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        // 3. Success state: Menampilkan ListView berisi 3 item statistik
        data: (statsList) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: statsList.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(statsList[index]),
            );
          },
        ),
      ),
    );
  }
}
