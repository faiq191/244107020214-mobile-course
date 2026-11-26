/// Week 12 — pure domain rule for a new announcement title.
///
/// Extracted from the UI so it can be unit-tested without rendering a widget
/// (codelab §3.1: "a task title is valid when it contains non-whitespace
/// text"). The rule is intentionally pure Dart — no Flutter, no Dio, no
/// storage — so a test can call it directly.
///
/// Returns `true` when the trimmed title is non-empty. A title made only of
/// spaces is therefore invalid, which is the edge case the widget test in
/// `test/home_widget_test.dart` relies on.
bool isValidAnnouncementTitle(String value) => value.trim().isNotEmpty;
