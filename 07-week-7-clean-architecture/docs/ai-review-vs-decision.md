# AI review vs final decision — `feat/announcement-validation`

## The prompt

```
Review this Flutter PR as a senior Flutter dev.
Context: feature-first Clean Architecture
(presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Focus: correctness, architecture, tests. Ignore style.
Give the top 5 findings + severity (blocker/suggestion)
+ rationale + proposed code fix.
```

Scope given to the reviewer: the diff of `feat/announcement-validation`
against `develop` — `AnnouncementModel.fromMap` title validation +
`test/announcement_model_test.dart`.

## Raw AI output (top 5 findings)

| # | Severity | Finding | Proposed fix |
|---|----------|---------|--------------|
| 1 | suggestion | `map['title'] as String?` throws a raw `TypeError` (`type 'int' is not a subtype of type 'String?'`) when a backend row sends a non-String title, not the intended `ArgumentError` — the validator's own contract is bypassed by the cast. | Extract with `rawTitle is String ? rawTitle.trim() : ''` so every bad title funnels into the same `ArgumentError` path. |
| 2 | suggestion | Test gap: the new tests cover missing/empty/whitespace titles but not the non-String cast path, so finding 1 would have shipped unnoticed. | Add a regression test expecting `throwsArgumentError` for `title: 42`. |
| 3 | suggestion | One malformed row makes the *entire* feed fail to load; skipping the bad row would keep the other announcements visible. | Filter invalid rows inside `fetchAnnouncements` instead of throwing. |
| 4 | suggestion | Validation should live in a domain use case (like `Login`), not in the data-layer model — business rules belong in domain. | Add a `ValidateAnnouncement` use case. |
| 5 | suggestion | `id` is not validated the same way: `map['id'] as String? ?? '?'` still lets a blank id through, and `home_page.dart` routes by `context.go('/announcement/${item.id}')`, so a blank id creates a dead route. | Validate `id` alongside `title`. |

## Verification checklist (observation → impact → decision)

| # | Does it really exist? Evidence | Dependency-rule violation in the fix? | Final decision | Reason |
|---|-------------------------------|----------------------------------------|----------------|--------|
| 1 | **YES — proven by a failing test.** Added the regression test first; it failed with `_TypeError: type 'int' is not a subtype of type 'String?' in type cast` at `announcement_model.dart:17` instead of `ArgumentError`. Output stored in this file's Evidence section. | No — pure Dart change inside the data model. | **ACCEPTED — fixed** in commit `fix(announcement): treat non-string titles as blank + regression test`. | The finding is real, the fix is 2 lines, and it makes the error path deterministic for the repository's catch-all. |
| 2 | **YES — grep evidence.** Before the fix commit, `test/announcement_model_test.dart` had no case with a non-String title (`grep -n "42" test/announcement_model_test.dart` → 0 matches). | No. | **ACCEPTED — fixed** (same commit, the test is the proof: red before, green after). | Exactly the "missing failure case" the checklist warns about. |
| 3 | **YES, the behavior is as described** (one bad row → whole fetch returns `LocalFailure` → error UI + Retry). | The proposed filter would live in the repository — no violation. | **REJECTED.** | Fail-loud is the intended design: silently dropping rows hides a backend data bug from everyone except a sharp-eyed user counting tiles. The error state is visible, testable, and recoverable via Retry. Skipping is a product decision, not a correctness bug. |
| 4 | **Partially true** — but the codebase documents the opposite decision in `announcement_providers.dart`: no use case for a single-line fetch with zero business rules. Mapping integrity is a data-layer concern. | A use case in domain would be legal, but it would only re-throw. | **REJECTED.** | Adding `ValidateAnnouncement` would be a pass-through use case — the exact over-engineering the Week 7 providers comment rules out. Validation at the mapping boundary is where the data enters; there is no user input path to validate. |
| 5 | **YES — grep evidence.** `grep -n "item.id" lib/features/announcement/presentation/pages/home_page.dart` → `context.go('/announcement/${item.id}')`; and `fromMap` still defaults blank ids to `'?'`. | No. | **ACCEPTED as a follow-up, deliberately not in this PR.** | Real, but it is pre-existing behavior outside this diff; bundling it here would widen the PR past one logical change. Tracked as a follow-up issue instead. |

Score: **3 findings verified correct (2 fixed in this PR, 1 follow-up), 2 rejected with written reasons.**

## Final decision

Merge after re-review. The AI review was directionally useful — finding 1 was
a genuine hole in the validation added by this very PR — but 2 of its 5
suggestions would have added either silent data loss (3) or ceremony code
(4). Verdict per finding, not wholesale acceptance.

## Evidence

**Failing test before the fix (finding 1 + 2):**

```
00:00 +5 -1: ... throws ArgumentError, not TypeError, when the title is not a String [E]
  Expected: throws <Instance of 'ArgumentError'>
    Actual: <Closure: () => AnnouncementModel>
     Which: threw _TypeError:<type 'int' is not a subtype of type 'String?' in type cast>
            stack package:campus_notify/features/announcement/data/models/announcement_model.dart 17:33
```

**After the fix (2026-10-30):**

```
flutter test      → 00:07 +10: All tests passed!
dart format --set-exit-if-changed lib test → 0 changes needed
flutter analyze   → No issues found!
```

**Grep used for finding 5:**

```
$ grep -n "item.id" lib/features/announcement/presentation/pages/home_page.dart
60:              onTap: () => context.go('/announcement/${item.id}'),
```
