# AI Initial Output - Week 7 Clean Architecture Challenge

The first raw output of the AI coding assistant (before manual fixes):

## 1. Structure proposed by the AI

```
lib/
|-- main.dart
|-- routes.dart
|-- core/
|   |-- failures.dart
|   |-- constants.dart            # AI proposal: no real need yet
|   |-- utils/
|   |   +-- validators.dart       # AI proposal: email validator moved here
|   +-- messaging/push_service.dart
+-- features/
    |-- auth/
    |   |-- domain/
    |   |   |-- entities/{auth_session.dart, user.dart}
    |   |   |-- repositories/auth_repository.dart
    |   |   +-- usecases/{login.dart, logout.dart, refresh_token.dart, get_saved_session.dart}
    |   |-- data/
    |   |   |-- models/auth_session_model.dart
    |   |   |-- datasources/{auth_remote_data_source.dart, auth_local_data_source.dart}
    |   |   +-- repositories/auth_repository_impl.dart
    |   +-- presentation/{providers/auth_providers.dart, pages/login_page.dart}
    +-- announcement/
        |-- domain/
        |   |-- entities/announcement.dart
        |   |-- repositories/announcement_repository.dart
        |   +-- usecases/{get_announcements.dart, get_announcement_by_id.dart}
        |-- data/ ...
        +-- presentation/ ...
```

## 2. Riverpod wiring given by the AI

```dart
final dioProvider = Provider<Dio>((ref) => Dio(BaseOptions(baseUrl: kApiBaseUrl)));
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
final authRemoteDataSourceProvider = Provider((ref) =>
    AuthRemoteDataSource(ref.read(dioProvider)));
final authLocalDataSourceProvider = Provider((ref) =>
    AuthLocalDataSource(ref.read(tokenStoreProvider)));
final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider),
                       ref.read(authLocalDataSourceProvider)));
final loginUseCaseProvider = Provider((ref) => Login(ref.read(authRepositoryProvider)));
```

## 3. Initial state (before manual review)

- The `Login` use case already returned the record `({AuthSession? session, Failure? failure})` - good.
- But the AI also generated `get_saved_session.dart` wrapping a single repository call - no logic at all.
- The AI split out `auth_session_model.dart` even though `AuthSession` is a pure entity with no JSON at all (the model would be identical to the entity).
- `validators.dart` was placed in `core/` although the email validator is used by one feature only.
- The AI did not say where the 401 interceptor should be attached after splitting the datasources.
- The remote/local datasource structure above feels excessive for one small repository.
