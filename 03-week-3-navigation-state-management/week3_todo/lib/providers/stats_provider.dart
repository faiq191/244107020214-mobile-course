import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier yang mengelola asynchronous state untuk daftar statistik
class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return _fetchStats();
  }

  // Simulasi pemanggilan API / database dengan delay 2 detik dan kemungkinan gagal 30%
  Future<List<String>> _fetchStats() async {
    // 1. Simulasi network latency selama 2 detik
    await Future.delayed(const Duration(seconds: 2));

    // 2. Simulasi failure rate sebesar ~30%
    final random = Random();
    if (random.nextDouble() < 0.3) {
      throw Exception('Network timeout: Failed to fetch statistics data');
    }

    // 3. Mengembalikan 3 item statistik jika sukses (immutable list)
    return const [
      'Total Users: 12,450',
      'Active Sessions: 1,280',
      'Conversion Rate: 4.8%',
    ];
  }

  // Aksi untuk memuat ulang data secara manual dengan error handling guard
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchStats());
  }
}

// Provider dideklarasikan dengan tipe eksplisit
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);
