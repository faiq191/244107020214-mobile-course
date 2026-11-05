// v2 - the fix I accepted after the six-step verification (docs/ai-log.md).
//
// v1 (raw AI output, preserved verbatim in docs/ai-log.md) called
// String.contains(q, caseSensitive: false), but Dart's String.contains is
// contains(Pattern other, [int startIndex = 0]) - there is NO caseSensitive
// named parameter. flutter analyze failed with undefined_named_parameter at
// both call sites (22:33 and 23:35) - the RED evidence captured in the
// README. The fix: normalize both sides with toLowerCase() and compare with
// the plain contains(). Still pure Dart - no Flutter/Dio/SQLite imports in
// the domain layer - and under the 80-line limit.
import '../entities/announcement.dart';

/// Returns announcements whose title or preview contains [query],
/// case-insensitively. An empty or blank query returns the whole list.
List<Announcement> filterAnnouncements(List<Announcement> items, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return List.of(items);

  return items
      .where(
        (a) =>
            a.title.toLowerCase().contains(q) ||
            a.preview.toLowerCase().contains(q),
      )
      .toList();
}
