import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({this.items = const [], this.throwError = false})
    : super(openDb: () => throw UnimplementedError());

  final List<Note> items;
  final bool throwError;

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) throw Exception('db locked (simulated)');
    return items;
  }

  @override
  Future<int> countDirty() => Future.value(items.where((n) => n.dirty).length);
}

void main() {
  test('fromMap is safe against missing fields', () {
    final note = Note.fromMap({'title': 'Groceries'});
    expect(note.title, 'Groceries');
    expect(note.body, '');
    expect(note.dirty, isFalse);
  });

  test('dirty flag survives serialization', () {
    final note = Note(
      title: 'a',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );
    final restored = Note.fromMap(note.toMap());
    expect(restored.dirty, isTrue);
  });

  test('provider succeeds with a fake repository', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(
            items: [Note(title: 'Test', updatedAt: DateTime.now())],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notes = await container.read(notesProvider.future);
    expect(notes.length, 1);
    expect(notes.first.title, 'Test');
  });

  test('provider fails with a fake repository', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(throwError: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.listen(notesProvider, (_, _) {});

    await pumpEventQueue();

    final state = container.read(notesProvider);

    expect(state.hasError, isTrue);
    expect(state.error, isA<Exception>());
  });
}
