import '../../../../core/failures.dart';

/// In-memory cache used by the repository as the local data source.
///
/// Week 11 optimisation: the original Week 10 repository re-fetched the mock
/// API on every read (and every widget rebuild that invalidated the provider).
/// A repository-level cache means a second visit paints instantly from memory
/// while the network refresh happens in the background
/// (stale-while-revalidate, codelab §6.1).
///
/// It deliberately mirrors the shape a Hive/SQLite box would have
/// (`read`/`write`/`clear`) so swapping the backend is a data-layer-only change.
class AnnouncementCache {
  List<Map<String, Object?>>? _rows;

  bool get isEmpty => _rows == null || _rows!.isEmpty;

  /// Returns a defensive copy so callers cannot mutate the cache by accident.
  List<Map<String, Object?>> read() => List.of(_rows ?? const []);

  Future<void> write(List<Map<String, Object?>> rows) async {
    _rows = List.of(rows);
  }

  Future<void> clear() async {
    _rows = null;
  }

  /// Provenance tag for the UI / docs ("cache" or "network").
  static Failure cacheMiss() =>
      const LocalFailure('No cached announcements available.');
}
