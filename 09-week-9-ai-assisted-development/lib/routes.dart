/// Single source of truth for every route string in the app.
///
/// Both GoRouter (main.dart) and the FCM deep-link parser (push_service.dart)
/// import these constants, so renaming a route can never desynchronize
/// navigation from push payloads (Refactoring Challenge, item 1).
class Routes {
  static const home = '/';
  static const login = '/login';
  static const tokenDebug = '/debug/token';
  static const announcementBase = '/announcement';

  static String announcement(String id) => '$announcementBase/$id';
}

/// Pure function: FCM `data` payload -> in-app route.
///
/// Extracted from the push service so it can be unit-tested without Firebase
/// (Refactoring Challenge, item 2). A missing or malformed `route` falls back
/// to the home route, mirroring the lab spec (`data['route'] ?? '/'`).
String routeFromMessage(Map<String, dynamic> data) {
  final raw = data['route'];
  if (raw is String && raw.isNotEmpty) {
    return raw.startsWith('/') ? raw : '/$raw';
  }
  return Routes.home;
}
