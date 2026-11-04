# AI Prompt - Week 7 Clean Architecture Challenge

The exact prompt sent to the AI coding assistant:

> My Flutter project: **campus_notify** (auth + FCM + announcement list), continued from Week 6. Current state: flat `lib/{data, providers, pages, messaging}` folders, repositories mixed with implementations, widgets calling Dio directly.
>
> Tasks:
> 1. Propose a feature-first Clean Architecture structure (presentation/domain/data) for the **auth + announcements** features.
> 2. For each old file, state its new destination (move/split/delete).
> 3. Flag what would be **over-engineering** if applied to simple CRUD, and when a use case is truly needed vs repository straight to notifier.
> 4. Show the **Riverpod DI wiring** (no extra DI package). Explain the trade-off of every decision.

Additional context given: tokens must still flow only through `flutter_secure_storage`, the Dio 401 refresh interceptor must be preserved, the FCM background handler must remain a top-level function, and FCM deep-link routing must keep working after the refactor.
