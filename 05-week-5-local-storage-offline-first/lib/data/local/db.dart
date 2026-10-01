import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'post.dart';

/// Membuka atau membuat database SQLite lokal (offline_notes.db)
Future<Database> openNotesDb() async {
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'offline_notes.db'),
    version: 1,
    onCreate: (db, version) async {
      // Tabel untuk menyimpan catatan lokal
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Tabel untuk menyimpan cache API posts
      await db.execute('''
        CREATE TABLE cached_posts(
          id INTEGER PRIMARY KEY,
          payload TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
    },
  );
}

/// Membaca data cache dari tabel cached_posts
Future<List<Post>> readCachedPosts() async {
  final db = await openNotesDb();
  final rows = await db.query('cached_posts');
  return rows.map((row) {
    final payload =
        json.decode(row['payload'] as String) as Map<String, dynamic>;
    return Post.fromMap(payload);
  }).toList();
}

/// Menyimpan atau memperbarui data cache ke tabel cached_posts
Future<void> savePostsToCache(List<Post> posts) async {
  final db = await openNotesDb();
  final batch = db.batch();

  // Bersihkan cache lama sebelum menyimpan data baru
  batch.delete('cached_posts');

  for (var post in posts) {
    batch.insert('cached_posts', {
      'id': post.id,
      'payload': post.toJson(),
      'cached_at': DateTime.now().toIso8601String(),
    });
  }

  await batch.commit(noResult: true);
}
