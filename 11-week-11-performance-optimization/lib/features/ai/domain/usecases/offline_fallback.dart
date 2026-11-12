/// Local fallback when the AI API is down, rate-limited or has no key.
///
/// This is deliberate: a campus app must still answer "what is happening
/// today?" from its cached announcements. Pure Dart, easy to test, and it
/// never calls the network.
String offlineFallbackReply(String question, List<String> contextItems) {
  final query = question.toLowerCase().trim();
  final matches = contextItems
      .where((item) => query.isEmpty || item.toLowerCase().contains(query))
      .take(3)
      .toList();

  if (matches.isNotEmpty) {
    return 'AI is unavailable right now. Offline results from cached '
        'announcements:\n${matches.map((m) => '• $m').join('\n')}';
  }

  return 'AI is unavailable right now. Please check the campus portal or '
      'try again in a moment. Your question is kept on this device only.';
}
