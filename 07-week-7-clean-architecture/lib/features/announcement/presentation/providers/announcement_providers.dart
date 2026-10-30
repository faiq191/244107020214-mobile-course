import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';

// Data layer.
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(),
);

// Presentation layer.
//
// AI Challenge decision — NO use case here: fetchAnnouncements is a
// single one-line CRUD call with zero business rules (no validation,
// sorting, or multi-repository combination). Repository -> provider
// directly; a GetAnnouncements use case would be pure over-engineering.
// A use case becomes mandatory the moment caching/sync logic appears.
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref
      .watch(announcementRepositoryProvider)
      .fetchAnnouncements();
  final failure = result.failure;
  if (failure != null) throw Exception(failure.message);
  return result.announcements;
});
