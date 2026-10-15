# Manual Fixes - Week 7 Clean Architecture Challenge

List of manual fixes applied to the AI's initial output ([ai-initial-output.md](ai-initial-output.md)), with the technical rationale:

## 1. Rejected: the `get_saved_session.dart` use case

- **Problem:** the AI generated a use case that only wraps a single `repository.getSavedSession()` call - zero business logic.
- **Fix:** deleted. The notifier reads the session straight from the repository. A use case is kept only when it orchestrates (e.g. `Login`, which validates input, calls the repo, then maps exceptions -> `Failure`).
- **Rationale:** a logic-free use case is a pass-through that adds files, boilerplate, and indirection for nothing. Classic over-engineering on simple CRUD operations.

## 2. Rejected: a separate `auth_session_model.dart`

- **Problem:** the AI split out `AuthSessionModel extends AuthSession` even though `AuthSession` has no JSON/serialization at all (tokens are stored as strings via `flutter_secure_storage`).
- **Fix:** the model was deleted; the `AuthSession` entity is used directly across all layers.
- **Rationale:** a model/entity split only pays off when real JSON <-> entity mapping exists. Forcing the pattern without need = duplication.

## 3. Moved: `validators.dart` out of `core/`

- **Problem:** the AI put the email validator in `core/utils/` although only one feature (auth) uses it.
- **Fix:** email validation moved into `features/auth/domain/usecases/login.dart` (as part of the use case's logic).
- **Rationale:** `core/` is for cross-feature code only. Single-feature code in core bloats core and destroys feature cohesion.

## 4. Fixed: placement of the 401 interceptor

- **Problem:** after the AI split the `datasources/`, it was unclear where the 401 refresh interceptor should be attached - a real risk of it getting lost during the refactor.
- **Fix:** the interceptor stays in `features/auth/data/api_client.dart`, the single source of `Dio` instances (`dioProvider`), so every request (auth and announcement alike) shares the same refresh policy.
- **Rationale:** token refresh is an HTTP-client-level cross-feature concern; it must live where Dio is created, not inside each datasource.

## 5. Simplified: no per-feature remote/local datasource split

- **Problem:** a `datasources/{remote,local}` structure for two small repositories is too heavy.
- **Fix:** the auth data layer is just `token_store.dart` (local choke point) + `api_client.dart` (remote) + `auth_repository_impl.dart`. No separate `datasources/` folders.
- **Rationale:** Clean Architecture is about dependency direction (`presentation -> domain <- data`), not folder count. Structure must stay proportional to feature size.

## 6. Kept from the AI (after verification)

- The `Login` use case returns the record `({AuthSession? session, Failure? failure})` instead of throwing - verified by unit test (`test/login_usecase_test.dart`).
- `AnnouncementModel extends Announcement` in the announcement feature - real JSON mapping exists there (API list/detail responses), so the model split is justified.
- `announcementsProvider` without a use case - consistent with the "use case only when there is logic" principle.

## Final decision

The AI scaffolding was accepted for the folder structure and Riverpod wiring, with the five corrections above applied. Every decision was weighed by its trade-off: disciplined structure (dependencies always point toward domain) vs boilerplate cost (rejected when there is no logic). All behavioral claims are verified via `flutter analyze` (0 issues) and `flutter test` (4/4 pass).
