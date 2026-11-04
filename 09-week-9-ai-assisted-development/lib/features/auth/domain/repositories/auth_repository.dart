import '../entities/auth_session.dart';

/// Repository CONTRACT (domain layer).
///
/// The implementation lives in ../../data/repositories/auth_repository_impl.dart
/// — the domain only knows the interface, so it can be faked in tests.
abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<String> refresh(String refreshToken);
}
