import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/providers/stats_provider.dart';

void main() {
  group('StatsNotifier Unit Tests', () {
    test('StatsNotifier initial state transitions from AsyncLoading to data or error', () async {
      // Inisialisasi ProviderContainer untuk unit test terisolasi
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Pastikan state awal saat provider pertama kali dibaca adalah AsyncLoading
      final subscription = container.listen(statsProvider, (_, _) {});
      expect(subscription.read(), isA<AsyncLoading<List<String>>>());

      // Tunggu hingga future internal selesai dieksekusi
      await container
          .read(statsProvider.future)
          .then((data) {
            // Jika sukses, harus mengembalikan 3 item statistik
            expect(data.length, 3);
            expect(data, contains('Total Users: 12,450'));
          })
          .catchError((error) {
            // Jika terkena kegagalan 30%, state container harus berupa AsyncError
            expect(
              container.read(statsProvider),
              isA<AsyncError<List<String>>>(),
            );
          });
    });
  });
}
