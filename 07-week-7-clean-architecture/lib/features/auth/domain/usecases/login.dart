import '../../../../core/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Success/failure paired in a record — no exception leaks into presentation.
typedef LoginResult = ({AuthSession? session, Failure? failure});

/// Business operation: validate credentials, then authenticate.
///
/// This use case is justified (not over-engineering) because it OWNS a
/// business rule — credential validation — before touching the repository.
class Login {
  const Login(this._repository);

  final AuthRepository _repository;

  Future<LoginResult> call({
    required String email,
    required String password,
  }) async {
    if (!email.contains('@')) {
      return (session: null, failure: const AuthFailure('Email is not valid'));
    }
    if (password.length < 6) {
      return (
        session: null,
        failure: const AuthFailure('Password must be at least 6 characters'),
      );
    }
    try {
      final session = await _repository.login(email: email, password: password);
      if (!session.isValid) {
        return (
          session: null,
          failure: const AuthFailure('The server returned an empty session'),
        );
      }
      return (session: session, failure: null);
    } catch (e) {
      return (session: null, failure: AuthFailure('Login failed: $e'));
    }
  }
}
