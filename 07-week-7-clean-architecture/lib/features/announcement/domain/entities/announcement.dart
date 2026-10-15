/// Pure entity (domain). No Flutter import, no JSON/Map mapping —
/// mapping lives in the data layer model.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.preview,
    this.body = '',
  });

  final String id;
  final String title;
  final String preview;
  final String body;
}
