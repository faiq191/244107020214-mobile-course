import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'pages/token_debug_page.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Bumped whenever authStateProvider changes so the router re-runs its
  // redirect (login/logout both trigger this).
  final refresh = ValueNotifier(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(authStateProvider).value ?? false;
      final goingLogin = state.matchedLocation == Routes.login;
      if (!loggedIn && !goingLogin) return Routes.login;
      if (loggedIn && goingLogin) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
    GoRoute(path: Routes.tokenDebug, builder: (_, _) => const TokenDebugPage()),
      GoRoute(path: Routes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: '${Routes.announcementBase}/:id',
        builder: (_, s) => AnnouncementPage(id: s.pathParameters['id'] ?? ''),
      ),
    ],
  );
});

class CampusNotifyApp extends ConsumerWidget {
  const CampusNotifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Campus Notify',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase may be unconfigured on a fresh checkout (no google-services.json
  // / firebase_options.dart yet). Degrade gracefully: auth + announcements
  // keep working without push, and `flutterfire configure` finishes setup.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    // ignore: avoid_print
    print('[Firebase] init skipped: $e');
  }

  // One container shared between main() and runApp so the push wiring can
  // reach providers (api client, token mirror) before the first frame.
  final container = ProviderContainer();
  final router = container.read(routerProvider);

  final push = PushService(
    registerToken: (token) async {
      // Mirror for the debug UI (render it only through maskToken()).
      container.read(fcmTokenProvider.notifier).state = token;
      try {
        // Lab 2: register/rotate the device token on the backend.
        await container
            .read(apiClientProvider)
            .post<void>('/devices', data: {'token': token});
      } catch (e) {
        // A backend hiccup must never break push initialization.
        // ignore: avoid_print
        print('[FCM] token registration failed: $e');
      }
    },
  );

  try {
    // Deep-link taps land here; the router redirect still guards
    // unauthenticated users (they bounce to /login first).
    await push.init(onDeepLink: router.go);
  } catch (e) {
    // ignore: avoid_print
    print('[FCM] push init skipped: $e');
  }

  // Riverpod 3: a pre-built container must be passed via UncontrolledProviderScope.
  runApp(
    UncontrolledProviderScope(container: container, child: const CampusNotifyApp()),
  );
}
