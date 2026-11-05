import '../../../../core/failures.dart';

/// Raised when the AI provider rejects the request. Keeping this in the
/// domain layer lets the notifier show a friendly message without importing
/// Dio or any other data-layer package.
class AiRequestException implements Exception {
  const AiRequestException(this.message, {this.retryable = false});

  final String message;

  /// True for transient failures (timeout, connection reset, 5xx). The notifier
  /// uses this to retry once through the non-streaming endpoint before falling
  /// back to cached data.
  final bool retryable;

  @override
  String toString() => message;
}

/// Repository contract for the AI provider.
///
/// The implementation (data layer) owns the HTTP client, the SSE parsing and
/// the secure-storage key lookup. The domain never knows which provider is
/// used, so switching Gemini -> OpenAI -> Hugging Face is a data-layer change.
abstract class AiRepository {
  /// Streams answer chunks as they arrive from the provider (SSE).
  Stream<String> streamAnswer({
    required String systemPrompt,
    required String userPrompt,
  });

  /// Non-streaming fallback used when the SSE endpoint is unavailable.
  Future<({String? reply, Failure? failure})> ask({
    required String systemPrompt,
    required String userPrompt,
  });

  Future<bool> hasApiKey();

  Future<void> saveApiKey(String apiKey);

  Future<void> clearApiKey();
}
