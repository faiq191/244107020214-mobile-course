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

  /// Throws [ArgumentError] when the title is missing or blank so a broken
  /// backend row fails loudly at the boundary instead of rendering an empty
  /// list tile; the repository catch converts it into a core Failure.
  factory AnnouncementModel.fromMap(Map<String, Object?> map) {
    final title = (map['title'] as String?)?.trim() ?? '';
    if (title.isEmpty) {
      throw ArgumentError.value(
        map['title'],
        'title',
        'Announcement title must not be blank (id: ${map['id'] ?? '?'})',
      );
    }
    return AnnouncementModel(
      id: map['id'] as String? ?? '?',
      title: title,
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

  Announcement toEntity() =>
      Announcement(id: id, title: title, preview: preview, body: body);
}
