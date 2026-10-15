import '../../../../core/failures.dart';
import '../entities/announcement.dart';

/// Repository CONTRACT (domain). Implementation lives in
/// ../../data/repositories/announcement_repository_impl.dart.
abstract class AnnouncementRepository {
  /// Success/failure paired in a record — no exception leaks into
  /// presentation (same pattern as the auth feature).
  Future<({List<Announcement> announcements, Failure? failure})>
      fetchAnnouncements();
}
