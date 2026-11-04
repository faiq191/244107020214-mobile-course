import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/features/auth/domain/usecases/login.dart';

/// Fake implementing the DOMAIN interface — no Dio, no Firebase, no storage.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.fail = false});

  final bool fail;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (fail) throw Exception('network down (simulated)');
    return const AuthSession(access: 'access-token', refresh: 'refresh-token');
  }

  @override
  Future<String> refresh(String refreshToken) => throw UnimplementedError();
}

void main() {
  test('Login returns a valid session on valid credentials', () async {
    final result = await Login(FakeAuthRepository())
        .call(email: 'student@campus.edu', password: 'secret123');

    expect(result.failure, isNull);
    expect(result.session, isNotNull);
    expect(result.session!.isValid, isTrue);
  });

  test(
    'Login returns AuthFailure instead of throwing on invalid email',
    () async {
      final result = await Login(FakeAuthRepository())
          .call(email: 'not-an-email', password: 'secret123');

      expect(result.failure, isA<AuthFailure>());
      expect(result.session, isNull);
    },
  );

  test('Login converts repository exceptions into AuthFailure', () async {
    final result = await Login(FakeAuthRepository(fail: true))
        .call(email: 'student@campus.edu', password: 'secret123');

    expect(result.failure, isA<AuthFailure>());
    expect(result.session, isNull);
  });
}
