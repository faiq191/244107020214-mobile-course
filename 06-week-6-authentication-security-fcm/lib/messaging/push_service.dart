import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Riverpod 3 moved StateProvider into the legacy library.
import 'package:flutter_riverpod/legacy.dart';

import '../routes.dart';

/// FCM token of this device, mirrored here by main() when it registers the
/// token. The debug UI must only ever show it through [maskToken].
final fcmTokenProvider = StateProvider<String?>((ref) => null);

/// UI-safe token preview: first 12 characters + `...`. Lab requirement: the
/// full token must never appear in report screenshots or logs.
String maskToken(String token) =>
    token.length <= 12 ? token : '${token.substring(0, 12)}...';

/// Background/terminated message handler.
///
/// MUST stay a top-level function annotated with @pragma('vm:entry-point'):
/// it runs in a separate isolate, so it can never touch BuildContext,
/// Riverpod, or any UI state. Keep the work here to light logging only -
/// navigation happens later, after the user taps the banner.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The background isolate does not share Dart state with main(), so Firebase
  // has to be initialized again before anything else touches it.
  await Firebase.initializeApp();
  // ignore: avoid_print
  print('[FCM-bg] ${message.messageId} data=${message.data}');
}

/// Push-notification lifecycle for the campus app (Labs 2 & 3):
/// permission -> token registration + rotation -> topic subscription ->
/// the three message states: foreground / background-tap / terminated-tap.
class PushService {
  PushService({required this.registerToken});

  /// Delivers every token (fresh + rotated) to the backend `POST /devices`.
  /// Injected so main() can also mirror it into [fcmTokenProvider] and tests
  /// can stub it.
  final Future<void> Function(String token) registerToken;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Call once after `Firebase.initializeApp()` and after the router exists.
  Future<void> init({required void Function(String route) onDeepLink}) async {
    final messaging = FirebaseMessaging.instance;

    // --- Lab 2: runtime permission (mandatory on Android 13+ / iOS). ---
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await _initLocalNotifications(onDeepLink);

    // --- Lab 2: token lifecycle. ---
    final token = await messaging.getToken();
    if (token != null) await registerToken(token);
    // MANDATORY listener: without it the backend keeps a stale token after
    // reinstall / data wipe / security rotation.
    messaging.onTokenRefresh.listen(registerToken);

    // --- Lab 3: broadcast topic for campus-wide announcements. ---
    await messaging.subscribeToTopic('campus-announcement');

    // --- Lab 3, foreground: the system shows NO banner while the app is
    // open, so raise a local notification manually. ---
    FirebaseMessaging.onMessage.listen(_showForegroundBanner);

    // --- Lab 3, background -> tapped. ---
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onDeepLink(routeFromMessage(message.data));
    });

    // --- Lab 3, terminated -> opened from the notification. ---
    final initial = await messaging.getInitialMessage();
    if (initial != null) onDeepLink(routeFromMessage(initial.data));
  }

  Future<void> _initLocalNotifications(
    void Function(String route) onDeepLink,
  ) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(
      settings: settings,
      // Foreground banner tap -> forward the deep-link payload to the router.
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) onDeepLink(payload);
      },
    );
  }

  Future<void> _showForegroundBanner(RemoteMessage message) async {
    final notification = message.notification;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'campus-announcement',
        'Campus announcements',
        channelDescription: 'Push announcements from Campus Notify',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    // flutter_local_notifications 22.x made every parameter named.
    await _local.show(
      id: message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: notification?.title ?? 'Campus announcement',
      body: notification?.body ?? '',
      notificationDetails: details,
      // The banner payload carries the deep-link route for the tap handler.
      payload: routeFromMessage(message.data),
    );
  }

  /// Broadcast controls for the topic lab (subscribe/unsubscribe from code).
  Future<void> subscribeToCampusTopic() =>
      FirebaseMessaging.instance.subscribeToTopic('campus-announcement');

  Future<void> unsubscribeFromCampusTopic() =>
      FirebaseMessaging.instance.unsubscribeFromTopic('campus-announcement');
}
