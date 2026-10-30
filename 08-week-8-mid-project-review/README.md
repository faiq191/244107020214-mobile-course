# Flutter Week 8 — Mid Project Review & Code Review

Mid-semester checkpoint for **campus_notify**: branch/commit hygiene, a small
peer-reviewed PR, machine-checked quality gates (analyze / format / test),
and a documented AI-review-vs-decision exercise. Continues the Week 5–7
project — no new app.

## Mid-Semester Status

The app behaves identically to the end of Week 7 (login, 401 auto-refresh,
FCM push, announcement list/detail). Week 8 added **process**, not features:

- `develop` is now the integration branch; `main` is never touched directly.
- All changes flow through feature branches → PR → review → merge.
- CI (`.github/workflows/ci.yml`) runs `flutter analyze`,
  `dart format --set-exit-if-changed .` and `flutter test` on every PR, and
  rejects dirty PRs before a human reads them.
- Machine checks are green locally: `flutter analyze` → *No issues found!*,
  `dart format` → 0 changes, `flutter test` → **10/10 passed**
  (3 login use case, 6 announcement title validation, 1 router smoke test).

## Issue / PR Map

| Issue | PR | Status |
|-------|----|--------|
| #1 Announcement rows with a missing/blank title render as empty list tiles | `feat/announcement-validation` → `develop` | opened, in peer review |

The PR description follows the repository PR template (problem, solution,
test steps, screenshots, checklist). Review findings and the
accept/reject log live in
[`07-week-7-clean-architecture/docs/ai-review-vs-decision.md`](../07-week-7-clean-architecture/docs/ai-review-vs-decision.md).

## Main Features (unchanged app + one hardening change)

- Secure login (access + refresh in secure storage) with GoRouter guard.
- Dio 401 auto-refresh interceptor (one refresh + one replay, then logout).
- FCM push in foreground / background / terminated with deep links.
- Announcement list + detail.
- **New in Week 8:** announcement rows without a valid title now fail loudly
  at the data boundary as a `Failure` (error UI + Retry) instead of rendering
  a blank tile — including the non-String-title case proven by a regression
  test.

## Tech Stack

Flutter 3.x · Riverpod · GoRouter · Dio · flutter_secure_storage · FCM ·
flutter_test · GitHub Actions (CI).

## How to Run

```bash
git checkout develop            # always branch from develop
cd 07-week-7-clean-architecture
cp .env.example .env            # set kApiBaseUrl
flutter pub get
flutterfire configure           # or reuse google-services.json
flutter run

# machine checks (all must be green before requesting review)
flutter analyze
dart format --set-exit-if-changed lib test   # CI uses `.` on a fresh checkout
flutter test
```

## Result Achieved

- History audited; 4 commit messages rewritten to Conventional Commits
  (before/after table with reasons in
  [`07-week-7-clean-architecture/docs/review-checklist.md`](../07-week-7-clean-architecture/docs/review-checklist.md)).
- Clean-architecture sterility greps: **0 hits** (no Flutter/Dio/SQLite/Firebase
  imports in domain; no `/data/` imports in domain or presentation).
- `feat/announcement-validation` is a 2-commit, 2-file PR — reviewable in
  under 15 minutes; AI findings were verified with failing tests/greps:
  3 accepted (2 fixed, 1 follow-up), 2 rejected with written reasons.
- Reflection: see the questions at the bottom of this README.

## Reflection

- **Blind LGTM vs responsible approve:** a blind LGTM risks shipping a broken
  main; a responsible approve means the reviewer checked out the branch, ran
  the machine checks plus a 5-minute manual test, and can name what they
  verified. The team pays later for every untested approval.
- **Request changes vs suggestion:** request changes for anything that breaks
  correctness or the dependency rule (null/state/error paths, cross-layer
  imports, missing failure tests); suggestions for readability and structure
  that don't change behavior.
- **AI findings rejected:** "skip bad rows instead of failing" (silently hides
  backend data bugs) and "add a ValidateAnnouncement use case" (pass-through
  ceremony the codebase explicitly rules out) — full reasoning in
  `docs/ai-review-vs-decision.md`.
- **Concrete fix after review:** non-String titles escaped validation as a raw
  `TypeError`; proven by a failing test, fixed, regression test added. Impact:
  the validator's contract is now deterministic for every bad-title shape.

## Screenshots

Capture guides and before/after evidence per feature: see
`07-week-7-clean-architecture/screenshots/`. Screenshots specific to this
week (error state on blank title, PR conversation, green CI run) go in
`screenshots/` of this folder — capture checklist in
[screenshots/README.md](screenshots/README.md).
