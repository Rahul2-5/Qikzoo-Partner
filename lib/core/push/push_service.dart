import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../providers/orders/dispatch_offer_provider.dart';
import '../../repositories/notifications/device_token_repository.dart';
import '../routes/app_routes.dart';

const dispatchOffersChannelId = 'dispatch_offers_channel';
const _dispatchOffersChannelName = 'Delivery offers';
const _dispatchOffersChannelDescription =
    'New delivery offers and dispatch alerts';

/// Must be top-level (or static) and `@pragma('vm:entry-point')` so the
/// Android engine can invoke it from a separate background isolate when the
/// app is backgrounded or killed. Runs with no access to the app's
/// ProviderContainer or GetX navigator — it only has to get a heads-up
/// system notification (sound + vibration) on screen; the actual offer
/// refresh/navigation happens later, when the rider taps it and the app's
/// main isolate handles `onMessageOpenedApp`/`getInitialMessage`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await PushService._initLocalNotificationsPlugin(plugin);
  await PushService._showHeadsUpNotification(message, plugin);
}

/// Owns the FCM token lifecycle and foreground/background/killed display of
/// incoming dispatch-offer pushes. Android-only for now — iOS has no
/// `GoogleService-Info.plist` yet (see ios/Runner/Info.plist), so every
/// entry point here is guarded to no-op safely on iOS rather than crash on
/// Firebase.initializeApp() with no config.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  ProviderContainer? _container;
  bool _initialized = false;

  Future<void> initialize(ProviderContainer container) async {
    _container = container;
    if (!Platform.isAndroid || _initialized) return;
    _initialized = true;

    await _initLocalNotificationsPlugin(_localNotifications);
    await _requestPermission();

    FirebaseMessaging.onMessage.listen(
      (message) => _showHeadsUpNotification(message, _localNotifications),
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleTap(message.data),
    );

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // On a true cold start (killed app), GetX's navigator isn't attached
      // to a route yet at this point — defer to the first built frame.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleTap(initialMessage.data),
      );
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
    await registerCurrentToken();
  }

  static Future<void> _initLocalNotificationsPlugin(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final data = Map<String, dynamic>.from(
          jsonDecode(payload) as Map,
        );
        PushService.instance._handleTap(data);
      },
    );

    const channel = AndroidNotificationChannel(
      dispatchOffersChannelId,
      _dispatchOffersChannelName,
      description: _dispatchOffersChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermission() async {
    await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  static Future<void> _showHeadsUpNotification(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final notification = message.notification;
    final title =
        notification?.title ?? message.data['title'] ?? 'New delivery request';
    final body = notification?.body ??
        message.data['body'] ??
        'Tap to view this delivery offer.';

    const androidDetails = AndroidNotificationDetails(
      dispatchOffersChannelId,
      _dispatchOffersChannelName,
      channelDescription: _dispatchOffersChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.call,
    );

    await plugin.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }

  void _handleTap(Map<String, dynamic> data) {
    if (data['type'] != 'NEW_DELIVERY_OFFER') return;
    _container?.read(dispatchOfferProvider.notifier).refresh();
    if (Get.currentRoute != AppRoutes.incomingOffer) {
      Get.toNamed(AppRoutes.incomingOffer);
    }
  }

  /// Called after a successful login/session restore.
  Future<void> registerCurrentToken() async {
    if (!Platform.isAndroid || _container == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
    } catch (_) {
      // FCM unavailable (no Play Services, permission denied, etc.) —
      // degrade to poll-only, never block login/app start.
    }
  }

  Future<void> _registerToken(String token) async {
    final container = _container;
    if (container == null) return;
    try {
      await container.read(deviceTokenRepositoryProvider).register(token);
    } catch (_) {
      // Best-effort — a failed registration must not block login.
    }
  }

  /// Called on logout, before local tokens are cleared.
  Future<void> removeCurrentToken() async {
    if (!Platform.isAndroid || _container == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _container!.read(deviceTokenRepositoryProvider).remove(token);
      }
    } catch (_) {
      // Best-effort — logout must always succeed locally regardless.
    }
  }
}
