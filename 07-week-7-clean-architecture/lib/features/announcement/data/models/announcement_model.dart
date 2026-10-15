import '../../domain/entities/announcement.dart';

/// Mapping ONLY here (Model extends entity): toMap/fromMap/toEntity never
/// appear on the domain entity — AI Verification Checklist, item 4.
class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.preview,
    super.body,
  });

  factory AnnouncementModel.fromMap(Map<String, Object?> map) {
    return AnnouncementModel(
      id: map['id'] as String? ?? '?',
      title: map['title'] as String? ?? '',
      preview: map['preview'] as String? ?? '',
      body: map['body'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'preview': preview,
        'body': body,
      };

  Announcement toEntity() => Announcement(
        id: id,
        title: title,
        preview: preview,
        body: body,
      );
}
