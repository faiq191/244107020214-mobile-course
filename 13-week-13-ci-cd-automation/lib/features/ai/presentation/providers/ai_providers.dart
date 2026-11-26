import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../announcement/domain/entities/announcement.dart';
import '../../../announcement/presentation/providers/announcement_providers.dart';
import '../../data/ai_key_store.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/usecases/build_campus_prompt.dart';
import '../../domain/usecases/offline_fallback.dart';

// ---- DI wiring: the only place implementations are chosen. ----

final aiKeyStoreProvider = Provider<AiKeyStore>((ref) => AiKeyStore());

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl(keyStore: ref.watch(aiKeyStoreProvider));
});

/// Used by the UI to show the "add an API key" banner. Never exposes the key.
final aiKeyConfiguredProvider = FutureProvider<bool>((ref) {
  return ref.watch(aiRepositoryProvider).hasApiKey();
});

/// Context is composed from the cached announcements at the presentation
/// boundary. The AI domain stays provider-agnostic and receives plain strings.
final aiContextProvider = Provider<String>((ref) {
  final AsyncValue<List<Announcement>> state = ref.watch(announcementsProvider);
  final items = state.value ?? const <Announcement>[];
  return items.take(6).map((a) => '${a.title} — ${a.preview}').join('\n');
});

// ---- Chat state and notifier. ----

class AiChatState {
  const AiChatState({
    this.messages = const <ChatMessage>[],
    this.isStreaming = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isStreaming;

  /// Friendly error from [mapAiError]; the fallback bubble is already added.
  final String? error;

  bool get hasFallback => messages.any((m) => m.isFallback);

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? error,
    bool clearError = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final aiChatProvider = NotifierProvider<AiChatNotifier, AiChatState>(
  AiChatNotifier.new,
);

class AiChatNotifier extends Notifier<AiChatState> {
  @override
  AiChatState build() => const AiChatState();

  Future<void> send(String raw) async {
    final question = raw.trim();
    if (question.isEmpty || state.isStreaming) return;

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(role: ChatRole.user, text: question),
        const ChatMessage(role: ChatRole.assistant, text: ''),
      ],
      isStreaming: true,
      clearError: true,
    );

    await _request(question);
  }

  Future<void> _request(String question) async {
    final prompt = buildCampusPrompt(
      question,
      context: ref.read(aiContextProvider),
    );

    try {
      final buffer = StringBuffer();
      await for (final chunk
          in ref
              .read(aiRepositoryProvider)
              .streamAnswer(
                systemPrompt: prompt.systemPrompt,
                userPrompt: prompt.userPrompt,
              )) {
        buffer.write(chunk);
        final visible = validateAiReply(buffer.toString());
        if (visible != null) _replaceLastAssistant(visible);
      }

      final finalText = validateAiReply(buffer.toString());
      if (finalText == null) {
        throw const AiRequestException(
          'The AI returned an empty or oversized answer.',
        );
      }

      _replaceLastAssistant(finalText, streaming: false);
      state = state.copyWith(isStreaming: false, clearError: true);
    } catch (e) {
      var message = e is AiRequestException
          ? e.message
          : 'The AI request failed. Using local data.';

      // SSE may be blocked by a proxy or fail on a flaky mobile network while
      // the normal generateContent endpoint still works. Retry once without
      // streaming before giving up and showing cached announcements.
      if (e is AiRequestException && e.retryable) {
        final result = await ref
            .read(aiRepositoryProvider)
            .ask(
              systemPrompt: prompt.systemPrompt,
              userPrompt: prompt.userPrompt,
            );
        final reply = result.reply == null
            ? null
            : validateAiReply(result.reply!);
        if (reply != null) {
          _replaceLastAssistant(reply, streaming: false);
          state = state.copyWith(isStreaming: false, clearError: true);
          return;
        }
        message = result.failure?.message ?? message;
      }

      final fallback = offlineFallbackReply(
        question,
        ref.read(aiContextProvider).split('\n'),
      );
      _replaceLastAssistant(fallback, fallback: true, streaming: false);
      state = state.copyWith(isStreaming: false, error: message);
    }
  }

  /// Re-sends the last question after a failure. The previous fallback bubble
  /// is dropped so the conversation has one answer per question.
  Future<void> retry() async {
    if (state.isStreaming) return;
    final lastUserIndex = state.messages.lastIndexWhere(
      (m) => m.role == ChatRole.user,
    );
    if (lastUserIndex < 0) return;

    final question = state.messages[lastUserIndex].text;
    state = state.copyWith(
      messages: [
        ...state.messages.sublist(0, lastUserIndex + 1),
        const ChatMessage(role: ChatRole.assistant, text: ''),
      ],
      isStreaming: true,
      clearError: true,
    );

    await _request(question);
  }

  void clear() {
    state = const AiChatState();
  }

  void _replaceLastAssistant(
    String text, {
    bool fallback = false,
    bool? streaming,
  }) {
    final messages = List.of(state.messages);
    if (messages.isEmpty || messages.last.role != ChatRole.assistant) return;

    messages[messages.length - 1] = messages.last.copyWith(
      text: text,
      isFallback: fallback,
    );
    state = state.copyWith(
      messages: messages,
      isStreaming: streaming ?? state.isStreaming,
    );
  }
}
