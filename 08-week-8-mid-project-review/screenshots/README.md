# Week 8 screenshot capture checklist

Run the app from the `feat/announcement-validation` branch and capture:

1. `01-error-state-blank-title.png` — the home page error + Retry state
   (simulated by temporarily adding a blank-title row to
   `AnnouncementRepositoryImpl._mockRows`, then reverting).
2. `02-pr-conversation.png` — the PR page showing the review comments and
   final approve.
3. `03-ci-green.png` — the GitHub Actions run for the PR with all steps green.
4. `04-flutter-test-local.png` — terminal output of `flutter test` (10/10).

Name files exactly as above so the README links stay stable.
