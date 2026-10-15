/// Domain failures — pure Dart, no Flutter and no packages.
///
/// The UI only ever receives a [Failure.message]; raw exceptions are
/// converted at the data -> domain boundary and never cross it.
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Something failed on-device (storage, parsing, unexpected state).
class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

/// Something failed on the network / backend side.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Authentication rejected or a credential is invalid.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
