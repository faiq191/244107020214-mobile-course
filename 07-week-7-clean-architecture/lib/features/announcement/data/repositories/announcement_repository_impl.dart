import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

/// Implementation of the [AnnouncementRepository] contract.
///
/// Mock source for now — swap `mockRows` for the Dio api_client call
/// (`dio.get('/announcements')` -> `AnnouncementModel.fromMap`) when the
/// real backend is connected. The interface and the UI stay untouched.
class AnnouncementRepositoryImpl implements AnnouncementRepository {
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

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      // Always convert Model -> Entity at the data -> domain boundary.
      final announcements = _mockRows
          .map((r) => AnnouncementModel.fromMap(r).toEntity())
          .toList();
      return (announcements: announcements, failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: LocalFailure('Failed to load announcements: $e'),
      );
    }
  }
}
