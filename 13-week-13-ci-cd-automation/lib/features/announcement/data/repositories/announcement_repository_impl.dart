import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../local/announcement_cache.dart';
import '../models/announcement_model.dart';

/// Implementation of the [AnnouncementRepository] contract.
///
/// Week 11 optimisations (see docs/performance-findings.md):
/// 1. **Repository cache (stale-while-revalidate).** The first call returns the
///    cached rows immediately when present, then refreshes from the "network"
///    in the background. That removes the 300 ms spinner on every re-entry.
/// 2. **Pagination.** [fetchPage] serves a bounded slice so a long list never
///    forces the full dataset through the widget tree.
///
/// Mock source for now — swap `_mockRows` for the Dio api_client call
/// (`dio.get('/announcements')` -> `AnnouncementModel.fromMap`) when the real
/// backend is connected. The interface and the UI stay untouched.
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({AnnouncementCache? cache})
    : _cache = cache ?? AnnouncementCache();

  final AnnouncementCache _cache;

  /// Latency of the simulated network call. Kept in one place so the
  /// profiling baseline and the post-optimisation run use the same source.
  static const simulatedLatency = Duration(milliseconds: 300);

  /// Page size used by the infinite-scroll list.
  static const pageSize = 10;

  static const List<Map<String, Object?>> _mockRows = [
    {
      'id': '1',
      'title': 'Midterm schedule posted',
      'preview': 'The midterm exam timetable is now available in the portal.',
    },
    {
      'id': '2',
      'title': 'Library extended hours',
      'preview':
          'The main library will stay open until 2 AM during finals week.',
    },
    {
      'id': '3',
      'title': 'Campus shuttle route change',
      'preview': 'Route B is detoured via the stadium until further notice.',
    },
  ];

  /// Number of synthetic rows generated for the pagination demo. Real data
  /// would come from the backend; the generator keeps the lab self-contained.
  static const _syntheticRowCount = 60;

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements() async {
    // 1. Serve cache immediately if we already have it.
    final cached = _cache.read();
    if (cached.isNotEmpty) {
      // 2. Refresh in the background (do not block the UI).
      unawaited(_refreshFromNetwork());
      return (announcements: _toEntities(cached), failure: null);
    }

    // 3. Cold start: hit the "network" once and populate the cache.
    try {
      final rows = await _networkRows();
      await _cache.write(rows);
      return (announcements: _toEntities(rows), failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: LocalFailure('Failed to load announcements: $e'),
      );
    }
  }

  @override
  Future<({List<Announcement> announcements, Failure? failure})> fetchPage(
    int page,
  ) async {
    if (page < 1) {
      return (
        announcements: const <Announcement>[],
        failure: const LocalFailure('Invalid page index.'),
      );
    }

    try {
      // Simulate a paginated network endpoint. The slice is bounded, so a
      // large dataset never crosses the boundary in one go.
      final rows = await _networkRows();
      final start = (page - 1) * pageSize;
      if (start >= rows.length) {
        return (announcements: const <Announcement>[], failure: null);
      }
      final end = (start + pageSize).clamp(0, rows.length);
      final slice = rows.sublist(start, end);
      return (announcements: _toEntities(slice), failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: LocalFailure('Failed to load page $page: $e'),
      );
    }
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> addAnnouncement(
    String title,
  ) async {
    try {
      // Simulate a POST /announcements mutation. In production this becomes
      // `dio.post('/announcements', data: {'title': title})` and the returned
      // row is mapped with AnnouncementModel.fromMap(...).toEntity().
      final created = AnnouncementModel(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        title: title.trim(),
        preview: 'Added locally — waiting for the backend to confirm.',
      );

      // Keep the cache coherent so a later fetch reflects the new row.
      final cached = _cache.read();
      await _cache.write([created.toMap(), ...cached]);

      return (announcement: created.toEntity(), failure: null);
    } catch (e) {
      return (
        announcement: null,
        failure: LocalFailure('Failed to add announcement: $e'),
      );
    }
  }

  Future<void> _refreshFromNetwork() async {
    try {
      final rows = await _networkRows();
      await _cache.write(rows);
    } catch (_) {
      // A background refresh failure must not break the visible cached list.
    }
  }

  Future<List<Map<String, Object?>>> _networkRows() async {
    await Future<void>.delayed(simulatedLatency);
    return _generateRows();
  }

  /// The three hand-written rows plus synthetic filler so pagination has
  /// something to scroll through. Deterministic, so profiling runs are
  /// comparable.
  List<Map<String, Object?>> _generateRows() {
    final rows = <Map<String, Object?>>[..._mockRows];
    for (var i = _mockRows.length; i < _syntheticRowCount; i++) {
      rows.add({
        'id': '${i + 1}',
        'title': 'Announcement ${i + 1}',
        'preview': 'Generated row ${i + 1} for the pagination demo.',
      });
    }
    return rows;
  }

  List<Announcement> _toEntities(List<Map<String, Object?>> rows) {
    // Always convert Model -> Entity at the data -> domain boundary.
    return rows.map((r) => AnnouncementModel.fromMap(r).toEntity()).toList();
  }
}

/// Fire-and-forget helper. `unawaited` is in dart:async but importing it just
/// for one call site would shadow nothing; a tiny local helper keeps the
/// imports minimal and the intent explicit.
void unawaited(Future<void> future) {
  future.ignore();
}
