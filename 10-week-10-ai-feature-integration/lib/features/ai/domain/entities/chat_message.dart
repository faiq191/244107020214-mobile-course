/// One bubble in the assistant conversation.
///
/// Pure domain entity: no Flutter import, no JSON mapping. The data layer
/// only deals with raw strings; the UI decides how a bubble looks.
enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.isFallback = false,
  });

  final ChatRole role;
  final String text;

  /// True when [text] comes from the offline fallback instead of the AI API.
  final bool isFallback;

  ChatMessage copyWith({String? text, bool? isFallback}) {
    return ChatMessage(
      role: role,
      text: text ?? this.text,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}
