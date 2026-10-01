import 'package:dio/dio.dart';

import '../local/db.dart';
import '../local/post.dart';
import 'note_repository.dart';

class PostRepository {
  final Dio _dio = Dio();

  // 1. Cache-first reads for API data
  Future<List<Post>> loadPostsCacheFirst({
    Function(List<Post>)? onBackgroundRefreshed,
  }) async {
    // 1. Ambil data cache lokal secara langsung agar UI tidak kosong
    final cached = await readCachedPosts();

    // 2. Jalankan ambil data baru dari jaringan di background (GET /posts)
    _refreshPostsInBackground(onBackgroundRefreshed);

    return cached;
  }

  Future<void> _refreshPostsInBackground(
    Function(List<Post>)? onRefreshed,
  ) async {
    try {
      final response = await _dio.get(
        'https://jsonplaceholder.typicode.com/posts',
      );
      if (response.statusCode == 200) {
        final List list = response.data;
        final posts = list
            .map((e) => Post.fromMap(e as Map<String, dynamic>))
            .toList();

        // Simpan data terbaru ke database SQLite
        await savePostsToCache(posts);

        // Beri tahu UI jika ada callback pembaharuan
        if (onRefreshed != null) {
          onRefreshed(posts);
        }
      }
    } catch (e) {
      // Jika offline/gagal koneksi, silent catch agar tidak merusak UI yang sudah menampilkan cache
      print('Background refresh skipped: offline/network error');
    }
  }

  // 2. Syncing dirty notes (Simulasi Upload ke Backend)
  Future<int> syncNotes(NoteRepository repo) async {
    final dirtyCount = await repo.countDirty();
    if (dirtyCount == 0) return 0;

    // Simulasi delay pengunggahan data ke server REST API
    await Future.delayed(const Duration(seconds: 1));
    await repo.markAllSynced(); // Tandai semua catatan telah tersinkronkan

    return dirtyCount;
  }
}
