/// Pure entity: a successful authentication result.
/// No Flutter import, no JSON mapping — mapping lives in the data layer.
class AuthSession {
  const AuthSession({required this.access, required this.refresh});

  final String access;
  final String refresh;

  bool get isValid => access.isNotEmpty && refresh.isNotEmpty;
}
