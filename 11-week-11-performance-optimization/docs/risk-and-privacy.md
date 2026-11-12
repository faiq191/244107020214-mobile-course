# Privacy, Cost, Error Handling and Fallback

This is the risk register required by the Week 10 codelab. The implementation
is in `lib/features/ai/`; the screenshot evidence is in `screenshots/`.

## Risk and mitigation table

| Risk | Impact | Mitigation in this project |
|---|---|---|
| User data leakage (NIK, phone, address, e-mail) | High | `redactSensitiveData()` runs before every request; unit tests assert the raw values are absent. The UI never asks for these fields. |
| API key leakage | High | Key is entered at runtime and stored with `flutter_secure_storage` (Android Keystore / iOS Keychain). It is sent in the `x-goog-api-key` header, never in source, docs, screenshots or a query string. |
| Cost spike | Medium | `maxOutputTokens: 1024` + `thinkingLevel: low`; context capped at 6 lines; no automatic request loop; send button disabled while streaming; no chat history resent. |
| API error / provider down | Medium | Friendly mapped message + offline fallback from cached announcements + `Retry` button. |
| Rate limit (429) | Medium | Explicit "wait a minute" message; no aggressive retry. A server-side quota is the next step for production. |
| Irrelevant or invented answer | Medium | System prompt instructs "use only the context" and "say you do not know"; replies are validated and long replies rejected. |
| Prompt injection via announcement text | Medium | Announcements are passed as context, not instructions; system prompt tells the model to ignore conflicting instructions. Server-side output filtering is documented as future work. |
| Sensitive data in logs | Medium | No prompt/response logging; errors are mapped to short messages before reaching the UI. |
| Stale offline data | Low | Fallback labels results as cached and points to the campus portal. |
| Double send / duplicate cost | Low | `isStreaming` gate in the notifier, disabled send button, retry returns early while streaming. |
| Key visible in screenshots | Low | Screenshots use a fake repository and an empty key dialog; no key is ever typed into the golden tests. |

## What is sent, and what is not

Sent to the provider:

- the redacted question;
- up to six cached announcement `title — preview` lines;
- the fixed system prompt.

Never sent:

- API key in a URL or log;
- token / refresh token / FCM token;
- NIK, phone number, e-mail, address, password or a pasted provider key;
- authentication headers from the campus backend;
- the whole announcement database.

## Error mapping

`mapAiError()` in `lib/features/ai/data/repositories/ai_repository_impl.dart`
turns `DioException` and provider errors into four domain failures:

| Provider result | Failure | User-facing result |
|---|---|---|
| 401 / 403 | `AuthFailure` | "AI API key was rejected" |
| 429 | `NetworkFailure` | "Rate-limited, wait a minute" |
| 5xx / timeout | `NetworkFailure` | "Temporarily unavailable" / "timed out" |
| 400 / 404 | `NetworkFailure` | "Request rejected" / "Model not available" |
| Empty / malformed body | `LocalFailure` | Offline fallback bubble |

## Fallback behaviour

```text
try the primary model (streaming)
  model 404 / 503 -> try gemini-3.6-flash, then gemini-3.1-flash-lite
  success -> replace the thinking bubble with the streamed text
  retryable failure (timeout / reset / 5xx)
           -> one non-streaming generateContent attempt (same model chain)
           -> success: show that answer
  still failing -> drop the empty bubble
           -> search cached announcements for the question
           -> show an "Offline fallback" bubble
           -> show the mapped error + Retry
```

The model chain stops after three models, so a 404 or an overloaded model costs
at most three attempts. 400/401/403/429 are project-wide and fail straight to
the fallback so a bad key or rate limit never multiplies the request count.
The non-streaming retry is also a single attempt, not a loop.

The fallback logic is pure and tested in
`test/ai_prompt_test.dart` (`offlineFallbackReply`): it returns up to three
matching cached announcements, otherwise it points the student to the campus
portal. It never calls the network.

## Data retention

- Chat messages live in Riverpod memory only; restarting the app clears them.
- The API key lives in secure storage until the user taps **Remove key**.
- No analytics or prompt logging is enabled.
- The golden tests use a fake repository, so no request leaves the machine.

## Production checklist (not implemented here)

- [ ] Proxy AI calls through the campus backend so the key never ships to a
      device.
- [ ] Per-account daily quota and token budget on the server.
- [ ] Prompt/response audit with PII redaction and a short retention window.
- [ ] Server-side output moderation/filtering.
- [ ] Explicit consent screen before the first AI request.
