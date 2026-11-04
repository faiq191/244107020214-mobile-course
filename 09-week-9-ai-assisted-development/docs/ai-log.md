# AI Log — Week 9: AI-Assisted Development

Feature: **announcement search + empty state** on top of the Week 7
`campus_notify` codebase (feature-first Clean Architecture, Riverpod 3,
Dio + SQLite).

This file is the technical-ownership record required by the codelab:
the prompt, the pasted context, the raw AI output, the verification run,
the hallucination evidence, the accept/reject decisions, and the AI review.

---

## 1. Lab 1 — Prompt and context engineering

### 1.1 Five-slot prompt (the prompt actually sent)

```text
Role: senior Flutter developer.

Context: existing feature-first project (presentation -> domain <- data),
Riverpod 3, Dio for remote, SQLite for local cache. Feature lives in
lib/features/announcement/. No new package may be added.

Task: add announcement title/preview search + an explicit empty state.
The search rule must be a pure domain use case; the widget must only
render state and forward the raw query.

Limits: keep the existing architecture; do not touch auth, routing, FCM,
the Dio interceptor, or the repository contract. Maximum 80 lines of
new production code.

Output: (1) the use case, (2) the provider wiring, (3) the widget delta,
(4) 3 test cases (case-insensitive match, no-match empty, blank query),
(5) how to run the tests.
```

### 1.2 Bad versus good prompt

| Bad | Good |
|-----|------|
| "make a cool announcement search" | "Add announcement title/preview search. Architecture: presentation -> domain <- data. No filtering inside widgets. Empty state + 1 widget test. Keep the existing repository contract." |

The good prompt names the layer boundary and the deliverable, so the AI
cannot silently put `.where()` inside the widget.

### 1.3 Context given (not secrets)

Included:

- Folder structure of `lib/features/announcement/` (domain/data/presentation).
- One repository contract (`AnnouncementRepository.fetchAnnouncements()`)
  and one entity (`Announcement{id,title,preview,body}`).
- Package versions from `pubspec.yaml`: `flutter_riverpod ^3.4.3`,
  `go_router ^18.0.2`, `flutter_lints ^6.0.0`, Dart SDK `^3.13.2`.
- Relevant snippets pasted as text, not screenshots.
- Explicit "must NOT change": auth flow, router redirect, FCM background
  handler, Dio 401 refresh interceptor, `announcementDetailPage`.
- Nullability note for the entity fields (all non-null `String`).

Excluded (privacy):

- FCM server key, device tokens, JWTs, refresh tokens, passwords, `.env`.
- Placeholders used instead: `TOKEN_PLACEHOLDER`, `JWT_PLACEHOLDER`.
- No whole-repo dump; only the 4 relevant files.

**Privacy rule applied:** no FCM token, JWT, or secret appears anywhere in
this log or in the screenshots. Masked token pages are documented with
`TOKEN_PLACEHOLDER` when referenced.

---

## 2. Lab 2 — Generate and verify search

### 2.1 Raw AI output v1 (verbatim, NOT accepted)

`lib/features/announcement/domain/usecases/filter_announcements.dart`:

```dart
// v1 — raw AI output, kept verbatim for the red evidence.
import '../entities/announcement.dart';

/// Returns announcements whose title or preview contains [query].
List<Announcement> filterAnnouncements(
  List<Announcement> items,
  String query,
) {
  final q = query.trim();
  if (q.isEmpty) return List.of(items);
  return items
      .where(
        (item) =>
            item.title.contains(q, caseSensitive: false) ||
            item.preview.contains(q, caseSensitive: false),
      )
      .toList();
}
```

The AI also returned this widget delta, which was **rejected** (filtering
inside the widget violates Lab 3):

```dart
// v1 — AI widget delta (rejected: business rule inside the UI layer)
final items = state.value ?? const <Announcement>[];
final visible = items
    .where((a) => a.title.toLowerCase().contains(_q.toLowerCase()))
    .toList();
```

### 2.2 Six-step verification

| Step | What was done | Result |
|------|---------------|--------|
| 1. Read every line | Read the v1 use case line by line; the `caseSensitive:` argument was flagged as "does this parameter exist?" | Flagged |
| 2. Check imports | `import '../entities/announcement.dart'` only — no Flutter/Dio/SQLite in `domain/` | Pass |
| 3. Check APIs | `String.contains` signature checked against the Dart SDK (`contains(Pattern other, [int startIndex = 0])`) | **Fail** |
| 4. Run `flutter analyze` until zero warnings | First run produced 2 errors (see 2.3) | **Red** |
| 5. Write 1 passing + 1 failing search test | `test/search_filter_test.dart` written before the fix; it fails to compile against v1, passes against v2 | **Red → Green** |
| 6. Manual test: empty query, match, no-match empty state | Covered by widget test + the three screenshots (`home-initial`, `home-filtered`, `home-empty`) | Pass |

### 2.3 RED evidence (verbatim analyzer output)

```text
Analyzing 09-week-9-ai-assisted-development...

  error - The named parameter 'caseSensitive' isn't defined. Try correcting the name to an existing named parameter or defining a new parameter for it - lib\features\announcement\domain\usecases\filter_announcements.dart:22:33 - undefined_named_parameter
  error - The named parameter 'caseSensitive' isn't defined. Try correcting the name to an existing named parameter or defining a new parameter for it - lib\features\announcement\domain\usecases\filter_announcements.dart:23:35 - undefined_named_parameter

2 issues found. (ran in 50.5s)
```

### 2.4 Root cause (proven, not guessed)

`String.contains` in Dart is:

```dart
bool contains(Pattern other, [int startIndex = 0])
```

There is **no** `caseSensitive` named parameter — the AI imported the
signature shape of `String.contains` from another language/older helper.
`flutter analyze` proved it at both call sites (`22:33`, `23:35`) with
`undefined_named_parameter`.

Grep proof that the bad parameter is gone from executable code (only the
explanatory comment remains):

```text
$ Get-ChildItem lib -Recurse -Filter *.dart | Select-String -Pattern 'caseSensitive'
filter_announcements.dart:4: // String.contains(q, caseSensitive: false), but Dart's String.contains is
filter_announcements.dart:5: // contains(Pattern other, [int startIndex = 0]) - there is NO caseSensitive
```

The test file was **not modified** between the red and green runs — the
only change was the use case implementation.

### 2.5 Accepted fix (v2, on disk)

```dart
// v2 - accepted after the six-step verification.
import '../entities/announcement.dart';

/// Returns announcements whose title or preview contains [query],
/// case-insensitively. An empty or blank query returns the whole list.
List<Announcement> filterAnnouncements(
  List<Announcement> items,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return List.of(items);
  return items
      .where(
        (item) =>
            item.title.toLowerCase().contains(q) ||
            item.preview.toLowerCase().contains(q),
      )
      .toList();
}
```

### 2.6 GREEN evidence (verbatim)

```text
Analyzing 09-week-9-ai-assisted-development...
No issues found! (ran in 6.9s)

00:05 +13: All tests passed!
```

`test/search_filter_test.dart` (the same file that was red) now covers:

- `filter ignores case` → `filterAnnouncements(list, 'groceries')` has length 2
- `no-match query returns empty` → `filterAnnouncements(list, 'zzz-missing')` is empty
- `empty or blank query returns all items`
- `matches on title OR preview`

### 2.7 Manual test (3 queries + screenshots)

| Query | Expected | Observed | Screenshot |
|-------|----------|----------|------------|
| *(empty)* | all announcements | 4 rows | [`screenshots/home-initial.png`](../screenshots/home-initial.png) |
| `midterm` | only "Midterm Schedule" | 1 row | [`screenshots/home-filtered.png`](../screenshots/home-filtered.png) |
| `zzz-missing` | empty state | "No announcements found" | [`screenshots/home-empty.png`](../screenshots/home-empty.png) |

---

## 3. Lab 3 — Debug and refactor

### 3.1 Reproduce

1. Run the app, open the announcement list.
2. Type `midterm` in the search field → only the matching row appears.
3. Type `zzz-missing` → the empty state appears with the retry-free message.
4. Input that triggered the original bug: any query, because v1 did not
   compile at all (`caseSensitive:`).

### 3.2 Isolate

The search rule was moved to a **pure use case**:
`lib/features/announcement/domain/usecases/filter_announcements.dart`.
It takes a `List<Announcement>` + `String` and returns a `List<Announcement>`
— no provider, no widget, no I/O, so it is testable in milliseconds.

### 3.3 Red test

`test/search_filter_test.dart` was written before the fix. Against v1 the
file does not compile (red); against v2 every case passes (green). The same
file is used for both runs — no test was weakened to make it pass.

### 3.4 Fix small, run analyze + tests

Fix = normalize both sides with `trim().toLowerCase()` and use the plain
`contains`. Nothing else changed. Then:

```text
flutter analyze   -> No issues found!
flutter test      -> All tests passed!
```

### 3.5 Layering after the refactor

```text
HomePage (widget)          UI only: TextField + list/empty state
   |
SearchQueryNotifier        state only: raw query string
   |
filterAnnouncements        pure domain rule (case-insensitive contains)
   |
AnnouncementRepository     data (Dio/SQLite behind the interface)
```

Proof the widget is UI-only:

```text
$ (Select-String home_page.dart -Pattern '\.where\(').Count
0
$ (Select-String home_page.dart -Pattern 'domain/usecases').Count
0
```

The widget does not import the use case and does not filter; it only reads
`filteredAnnouncementsProvider` and calls `searchQueryProvider.update`.

### 3.6 AI code size

The v1 use case was 17 lines, the rejected widget delta touched the widget,
and the final production change (use case + providers + widget delta) stays
under the 80-line limit. No function exceeds 40 lines; `HomePage.build`
delegates the empty state to `_EmptyState`.

---

## 4. AI Challenge — AI review of the search code

### 4.1 Review prompt used

```text
Review this Flutter search code as a senior dev.
Context: feature-first (presentation -> domain <- data),
Riverpod, SQLite + Dio.
Focus: correctness, architecture, tests. Ignore style.
Give 3 findings + blocker/suggestion level + reasons.
```

### 4.2 AI findings and decisions

| # | AI finding | Level | Decision | Technical reason | Evidence |
|---|------------|-------|----------|------------------|----------|
| 1 | "The widget still filters inline; move it to the provider/use case." | blocker | **Accept — proven true, fixed** | Filtering in `build` duplicates the domain rule and makes the widget untestable in isolation. | `grep '.where(' home_page.dart` → **0** matches after the fix; widget tests pass. |
| 2 | "Add a 300 ms debounce `Timer` in `searchQueryProvider`." | suggestion | **Reject — write manually not needed** | The list is a 4-item in-memory fixture; a `Timer` adds lifecycle/leak risk (`ref.onDispose`) and false test flakiness for zero measurable gain. Revisit only if the list is paginated or > ~5k rows. | `flutter test` already runs in ~3 s; no debounce test exists because there is no requirement. |
| 3 | "Move `searchQueryProvider` into the domain layer so the use case owns the query." | suggestion | **Reject — wrong layer** | The query is UI state, not a business rule. Putting it in `domain/` would drag `Notifier`/Riverpod into a layer that must stay framework-free. | `domain/usecases/filter_announcements.dart` imports only the entity; no `flutter_riverpod` import. |
| 4 | "Return `List<Announcement>` from the provider instead of `AsyncValue`." | suggestion | **Accept + refactor (kept `AsyncValue`)** | `filteredAnnouncementsProvider` must keep loading/error states from `announcementsProvider`; `whenData` preserves them while mapping only the data case. Returning a plain list would hide errors. | `HomePage` still uses `state.when(loading/error/data)`; widget tests cover the data path. |

### 4.3 Per-file decision table

| File | Decision | Reason |
|------|----------|--------|
| `domain/usecases/filter_announcements.dart` | **Reject v1, write manually (v2)** | v1 used a non-existent named parameter; v2 is a 12-line pure function. |
| `presentation/providers/announcement_providers.dart` | **Accept + refactor** | Kept the AI's derived-provider idea, replaced the raw list with `AsyncValue` + `whenData`, added `SearchQueryNotifier`. |
| `presentation/pages/home_page.dart` | **Accept + refactor** | AI wanted inline filtering; the widget was rewritten UI-only with `_EmptyState`. |
| `test/search_filter_test.dart` | **Accept (unchanged red→green)** | Written before the fix; proves the bug. |
| `test/home_page_search_test.dart` | **Accept + fix** | First version used a non-exported `Override` type (Riverpod 3); fixed by inlining the override list. |
| `test/screenshots_test.dart` | **Write manually** | Golden helper with a real Roboto `FontLoader` so the PNGs show text, not Ahem boxes. |

### 4.4 Extra verification catch (Riverpod 3)

The first widget-test helper was typed `Widget wrap(List<Override> overrides)`.
Riverpod 3 no longer exports `Override` publicly, so `flutter analyze` failed:

```text
error - The name 'Override' isn't a type, so it can't be used as a type argument - test\home_page_search_test.dart:29:20 - non_type_as_type_argument
1 issue found. (ran in 128.3s)
```

Fix: drop the parameter and build the override list inline. This is a second
real finding proven by `flutter analyze` and then fixed.

---

## 5. Self-verification checklist

- [x] Five-slot prompt + context recorded in this file.
- [x] `flutter analyze` clean (`No issues found!`).
- [x] `dart format --set-exit-if-changed .` clean.
- [x] `flutter test` green (13 tests).
- [x] 1 AI finding proven true (inline filtering) + fixed, with grep evidence.
- [x] 1 AI finding rejected with written reasons (debounce / domain query).
- [x] Red → green evidence with the **same** test file.
- [x] Raw v1 code preserved verbatim.
- [x] No secret/token/JWT in the log or screenshots.
- [x] Able to explain every decision without opening the AI.
