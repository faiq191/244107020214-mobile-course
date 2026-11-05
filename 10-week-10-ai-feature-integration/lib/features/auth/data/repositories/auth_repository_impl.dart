import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementation of the [AuthRepository] contract.
///
/// REPLACE the mock body with FirebaseAuth / the real backend once ready —
/// the domain interface and every consumer stay untouched.
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!email.contains('@') || password.length < 6) {
      throw Exception('Invalid email or password');
    }
    // Simulated JWT: header.payload.signature (never parse manually
    // in production, use server-side verification).
    return AuthSession(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
  }

  @override
  Future<String> refresh(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (refreshToken.isEmpty) throw Exception('Refresh token missing');
    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}
