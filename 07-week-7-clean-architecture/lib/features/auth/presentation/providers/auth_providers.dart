import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../data/api_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/token_store.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login.dart';

// ---- DI wiring: the single place where implementations are chosen. ----
// Widgets never call `new Something()` themselves; they only watch these.

// Data layer.
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(),
);

final apiClientProvider = Provider((ref) {
  return buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
  );
});

// Domain layer: the use case receives the abstraction, not the impl.
final loginProvider = Provider<Login>(
  (ref) => Login(ref.watch(authRepositoryProvider)),
);

// Presentation layer: state consumed by the UI + GoRouter redirect.
final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();

    // The use case returns a record; no exception ever reaches the UI.
    final result = await ref
        .read(loginProvider)
        .call(email: email, password: password);

    final failure = result.failure;
    if (failure != null || result.session == null) {
      state = AsyncError(
        failure ?? const LocalFailure('Login failed'),
        StackTrace.current,
      );
      return;
    }

    await ref
        .read(tokenStoreProvider)
        .save(access: result.session!.access, refresh: result.session!.refresh);
    state = const AsyncData(true);
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidateSelf();
  }
}
