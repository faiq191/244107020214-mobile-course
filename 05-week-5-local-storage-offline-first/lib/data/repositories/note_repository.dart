import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/data/local/note.dart';

class NoteRepository {
  NoteRepository({Future<dynamic> Function()? openDb});

  Future<List<Note>> fetchNotes() async {
    return [];
  }

  Future<int> countDirty() async {
    return 0;
  }

  // Method baru untuk mengatasi undefined_method
  Future<void> addNote(Note note) async {
    // Implementasi simpan ke database/local storage
  }

  Future<void> deleteNote(int id) async {
    // Implementasi hapus dari database/local storage
  }

  Future<void> markAllSynced() async {
    // Implementasi ubah status dirty menjadi false/synced
  }
}

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

final notesProvider = FutureProvider<List<Note>>((ref) async {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.fetchNotes();
});
