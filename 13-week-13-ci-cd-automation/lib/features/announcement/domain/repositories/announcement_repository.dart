import '../../../../core/failures.dart';
import '../entities/announcement.dart';

/// Repository CONTRACT (domain). Implementation lives in
/// ../../data/repositories/announcement_repository_impl.dart.
abstract class AnnouncementRepository {
  /// Success/failure paired in a record — no exception leaks into
  /// presentation (same pattern as the auth feature).
  ///
  /// Week 11: the implementation serves cached rows immediately and refreshes
  /// in the background (stale-while-revalidate).
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements();

  /// Week 11: bounded page for infinite scroll. Page numbering starts at 1.
  /// An empty list means "no more pages".
  Future<({List<Announcement> announcements, Failure? failure})> fetchPage(
    int page,
  );

  /// Week 12: persist a new announcement created by the user.
  ///
  /// Kept on the contract (not the widget) so the widget/integration tests can
  /// inject a fake repository that records the call, and so the real
  /// implementation can post to the backend without the UI changing.
  Future<({Announcement? announcement, Failure? failure})> addAnnouncement(
    String title,
  );
}
