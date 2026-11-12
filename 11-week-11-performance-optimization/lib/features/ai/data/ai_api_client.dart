import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/repositories/ai_repository.dart';
import 'ai_key_store.dart';

/// Thin Gemini client (data layer).
///
/// The model is pinned so a provider-side default change cannot silently
/// alter behaviour or cost. The API key is sent in the `x-goog-api-key`
/// header instead of the query string, which keeps it out of URLs and proxy
/// logs.
class AiApiClient {
  AiApiClient({Dio? dio, required this.keyStore})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
              connectTimeout: const Duration(seconds: 15),
              // Gemini 3.x can spend time "thinking" before the first SSE
              // chunk. 30 s was too aggressive on a phone/emulator network.
              receiveTimeout: const Duration(seconds: 60),
            ),
          );

  final AiKeyStore keyStore;
  final Dio _dio;

  static const models = <String>[
    // Primary: current stable Flash.
    'gemini-3.8-flash',
    // Fallbacks used only when the provider says the model is unavailable or
    // overloaded. Free-tier capacity is per model, so a 503 on one model can
    // still succeed on another.
    'gemini-3.6-flash',
    'gemini-3.1-flash-lite',
  ];

  /// True when another model in [models] is worth trying.
  ///
  /// 404 means the model is retired or not enabled for this key; 503 means the
  /// provider is temporarily overloaded. 400/401/403/429 are project-wide, so
  /// switching models would only add requests without a better chance.
  static bool shouldTryNextModel(Object error) {
    if (error is! DioException) return false;
    final status = error.response?.statusCode;
    return status == 404 || status == 503;
  }

  Future<String> _requireKey() async {
    final key = await keyStore.read();
    if (key == null || key.trim().isEmpty) {
      throw const AiRequestException(
        'No AI API key yet. Add one with the key button in the app bar.',
      );
    }
    return key;
  }

  Map<String, Object?> _payload({
    required String systemPrompt,
    required String userPrompt,
  }) {
    return {
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt},
          ],
        },
      ],
      'generationConfig': {
        // Gemini 3.8 ignores temperature/top_p/top_k and will reject them in a
        // future release, so they are removed. Low thinking keeps chat latency
        // and cost down; the token cap includes thinking tokens, hence 1024
        // rather than 256 (256 can be consumed by reasoning and return empty).
        'maxOutputTokens': 1024,
        'thinkingConfig': {'thinkingLevel': 'low'},
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    };
  }

  Options _options(String key) => Options(
    responseType: ResponseType.stream,
    headers: {'Content-Type': 'application/json', 'x-goog-api-key': key},
  );

  /// SSE endpoint: each `data:` line is one partial Gemini response.
  ///
  /// Tries [models] in order. A model is only skipped when the request fails
  /// before any text was emitted (404/503); once streaming has started a
  /// mid-stream error is surfaced instead of mixing two answers.
  Stream<String> stream({
    required String systemPrompt,
    required String userPrompt,
  }) async* {
    final key = await _requireKey();
    Object? lastError;

    for (final model in models) {
      var emitted = false;
      try {
        final response = await _dio.post<ResponseBody>(
          '/models/$model:streamGenerateContent',
          queryParameters: const {'alt': 'sse'},
          data: _payload(systemPrompt: systemPrompt, userPrompt: userPrompt),
          options: _options(key),
        );

        final body = response.data;
        if (body == null) {
          throw const AiRequestException('The AI provider returned no body.');
        }

        await for (final line
            in body.stream
                .cast<List<int>>()
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;

          final payload = trimmed.substring(5).trim();
          if (payload.isEmpty || payload == '[DONE]') continue;

          final text = _extractText(payload);
          if (text.isNotEmpty) {
            emitted = true;
            yield text;
          }
        }
        return;
      } catch (e) {
        lastError = e;
        if (emitted || !shouldTryNextModel(e)) rethrow;
      }
    }

    throw lastError ??
        const AiRequestException('No AI model is currently available.');
  }

  /// Non-streaming endpoint, used as a retry path when SSE fails.
  ///
  /// Uses the same model fallback chain as [stream].
  Future<String> ask({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final key = await _requireKey();
    Object? lastError;

    for (final model in models) {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          '/models/$model:generateContent',
          data: _payload(systemPrompt: systemPrompt, userPrompt: userPrompt),
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': key,
            },
          ),
        );

        final text = _extractTextMap(response.data);
        if (text.isEmpty) {
          throw const AiRequestException(
            'The AI provider returned an empty answer.',
          );
        }
        return text;
      } catch (e) {
        lastError = e;
        if (!shouldTryNextModel(e)) rethrow;
      }
    }

    throw lastError ??
        const AiRequestException('No AI model is currently available.');
  }

  String _extractText(String jsonPayload) {
    try {
      final data = jsonDecode(jsonPayload);
      if (data is Map<String, dynamic>) return _extractTextMap(data);
    } on FormatException {
      // A broken SSE line must not kill the whole stream.
      return '';
    }
    return '';
  }

  String _extractTextMap(Map<String, dynamic>? data) {
    final error = data?['error'];
    if (error is Map && error['message'] is String) {
      throw AiRequestException('AI provider error: ${error['message']}');
    }

    final candidates = data?['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';

    final content = (candidates.first as Map?)?['content'];
    final parts = (content as Map?)?['parts'];
    if (parts is! List) return '';

    final buffer = StringBuffer();
    for (final part in parts) {
      final partMap = part as Map?;
      // Gemini 3 may return reasoning/thought parts. They are not the answer.
      if (partMap?['thought'] == true) continue;
      final text = partMap?['text'];
      if (text is String) buffer.write(text);
    }
    return buffer.toString();
  }
}
