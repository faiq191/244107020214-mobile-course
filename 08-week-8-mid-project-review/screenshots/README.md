# Week 8 screenshot capture checklist

1. `01-error-state-blank-title.png` — **captured** on the Pixel 8 emulator
   from the `feat/announcement-validation` branch: a blank-title row was
   temporarily added to `AnnouncementRepositoryImpl._mockRows`, the app was
   run, and the home page shows the error + Retry state
   ("Failed to load announcements: ... title must not be blank (id: 4)").
   The temp row was reverted after the capture.
2. `02-pr-conversation.png` — PENDING: capture after the PR is opened and
   peer-reviewed (review comments + final approve).
3. `03-ci-green.png` — PENDING: capture after the PR triggers the CI workflow
   (all steps green).
4. `04-flutter-test-local.txt` — **captured**: raw `flutter test` output,
   10/10 passing (kept as text so the log stays copy-pasteable).

