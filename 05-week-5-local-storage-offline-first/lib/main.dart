import 'package:flutter/material.dart';

import 'data/local/note.dart';
import 'data/repositories/note_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const OfflineNotesPage(),
    );
  }
}

class OfflineNotesPage extends StatefulWidget {
  const OfflineNotesPage({super.key});

  @override
  State<OfflineNotesPage> createState() => _OfflineNotesPageState();
}

class _OfflineNotesPageState extends State<OfflineNotesPage> {
  final NoteRepository _repository = NoteRepository();
  List<Note> _notes = [];
  int _dirtyCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // Mengambil daftar catatan & jumlah data belum tersinkronisasi (dirty) dari SQLite
  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await _repository.fetchNotes();
    final dirtyCount = await _repository.countDirty();
    setState(() {
      _notes = notes;
      _dirtyCount = dirtyCount;
      _isLoading = false;
    });
  }

  // Dialog untuk menambah catatan baru
  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Catatan Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Isi Catatan',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isNotEmpty) {
                  await _repository.addNote(
                    title: titleController.text.trim(),
                    body: bodyController.text.trim(),
                  );
                  if (mounted) Navigator.pop(context);
                  _loadNotes();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // Menghapus catatan berdasarkan ID
  Future<void> _deleteNote(int id) async {
    await _repository.deleteNote(id);
    _loadNotes();
  }

  // Simulasi penandaan sinkronisasi (mark all synced)
  Future<void> _syncNotes() async {
    await _repository.markAllSynced();
    _loadNotes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua catatan berhasil disinkronkan!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Indicator jumlah data "dirty" (unsynced)[cite: 4]
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Badge(
                label: Text('$_dirtyCount'),
                child: IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync Notes',
                  onPressed: _syncNotes,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? const Center(child: Text('Belum ada catatan lokal.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      note.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note.body.isNotEmpty) ...[
                          Text(note.body),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          'Diperbarui: ${note.updatedAt.toString().split('.')[0]}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (note.dirty)
                          const Icon(
                            Icons.cloud_off,
                            color: Colors.orange,
                            size: 20,
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNote(note.id!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}
