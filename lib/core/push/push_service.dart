import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../providers/orders/dispatch_offer_provider.dart';
import '../../providers/orders/active_order_provider.dart';
import '../../repositories/notifications/device_token_repository.dart';
import '../routes/app_routes.dart';

// _v2: the default notification "ding" wasn't attention-grabbing enough for
// a rider to notice a real offer (reported directly by a rider testing this
// on-device) — switching to the device's ringtone sound instead. Android
// notification channels are immutable once created (sound/importance can't
// be changed on an existing channel id, only by the user in Settings), so
// this needed a new channel id to actually take effect on devices that
// already had the old channel from a prior install.
const dispatchOffersChannelId = 'dispatch_offers_channel_v2';
const _dispatchOffersChannelName = 'Delivery offers';
const _dispatchOffersChannelDescription =
    'New delivery offers and dispatch alerts';
const _dispatchOffersSound =
    UriAndroidNotificationSound('content://settings/system/ringtone');

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
  // No dedup guard here deliberately: this runs in its own throwaway
  // background isolate with no access to the main isolate's
  // `PushService.instance` state, and the dashboard's poll timer is always
  // cancelled while the app is backgrounded/killed (see
  // `_DashboardHomeScreenState.didChangeAppLifecycleState`) — so there is no
  // second alert source to collide with while this handler can run.
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

  /// The dispatch attempt id most recently alerted for in the foreground —
  /// FCM's `onMessage` listener and the dashboard's own poll timer can both
  /// detect the very same offer while the app is in the foreground, and
  /// without this guard each would independently call `plugin.show()`,
  /// producing two sounds/vibrations for one real offer. Keyed by the
  /// backend's dispatch attempt id (`DispatchOfferModel.id` /
  /// `message.data['attemptId']`) — the one identity both paths agree on.
  String? _lastAlertedOfferId;

  Future<void> initialize(ProviderContainer container) async {
    _container = container;
    if (!Platform.isAndroid || _initialized) return;
    _initialized = true;

    await _initLocalNotificationsPlugin(_localNotifications);
    await _requestPermission();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
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
      sound: _dispatchOffersSound,
      enableVibration: true,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermission() async {
    await requestPermissionAndRegister();
  }

  /// Manually re-triggers the OS notification-permission prompt (e.g. from
  /// the Notifications screen's "Enable alerts" card) and, if granted,
  /// registers the current FCM token — the same real permission/token
  /// pipeline `initialize()` runs once at app start, callable again later
  /// for a rider who dismissed it the first time. Returns the actual
  /// granted/denied outcome so the caller can show a truthful result
  /// instead of an unconditional success message.
  Future<bool> requestPermissionAndRegister() async {
    if (!Platform.isAndroid) return false;
    final settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    if (granted) await registerCurrentToken();
    return granted;
  }

  /// One dispatch attempt always maps to the same local-notification id,
  /// whether it was raised via FCM or via the poll-detected path — calling
  /// `plugin.show()` twice with this id updates the same notification
  /// instead of stacking a second one. Falls back to a random-ish id only
  /// when no attempt id is available (shouldn't happen for a real offer
  /// payload, but never skip showing a genuine push over a missing field).
  static int _offerNotificationId(String? attemptId) =>
      (attemptId != null && attemptId.isNotEmpty)
          ? attemptId.hashCode
          : DateTime.now().millisecondsSinceEpoch;

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

    await _showLocalAlert(
      plugin,
      id: _offerNotificationId(message.data['attemptId'] as String?),
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }

  /// Foreground-only entry point for FCM pushes — deduplicates against the
  /// dashboard's poll timer, which is only ever running while the app is in
  /// the foreground (see `didChangeAppLifecycleState`), so this is the one
  /// place the two detection paths can race for the same offer.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final attemptId = message.data['attemptId'] as String?;
    if (!_claimAlert(attemptId)) return;
    await _showHeadsUpNotification(message, _localNotifications);
  }

  /// Returns true (and records the claim) if this is the first alert this
  /// session for [attemptId] — false if a sibling detection path already
  /// alerted for the same offer. A null/empty id (shouldn't happen for a
  /// real offer) is never deduplicated, since there's no shared identity to
  /// compare against.
  bool _claimAlert(String? attemptId) {
    if (attemptId == null || attemptId.isEmpty) return true;
    if (_lastAlertedOfferId == attemptId) return false;
    _lastAlertedOfferId = attemptId;
    return true;
  }

  static Future<void> _showLocalAlert(
    FlutterLocalNotificationsPlugin plugin, {
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      dispatchOffersChannelId,
      _dispatchOffersChannelName,
      channelDescription: _dispatchOffersChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: _dispatchOffersSound,
      enableVibration: true,
      category: AndroidNotificationCategory.call,
      // Defense-in-depth alongside the id-based dedup above: if this same
      // notification id is ever re-posted (e.g. a race this guard didn't
      // anticipate), Android updates the visible notification without
      // replaying the sound/vibration a second time.
      onlyAlertOnce: true,
    );

    await plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  /// Plays the same sound/vibration/heads-up alert as an FCM-delivered
  /// offer push, but for an offer this device *detected itself* via the
  /// dashboard's own poll loop (`AppConstants.dispatchOfferPollInterval`).
  /// FCM delivery is best-effort — `DeviceTokensService.notifyUser` on the
  /// backend silently no-ops if the rider has no registered token, or the
  /// push can simply be delayed/dropped — so polling is this app's only
  /// *guaranteed* offer-detection path, and it must alert the rider exactly
  /// as loudly as a push would, or a real offer can silently expire
  /// unnoticed inside its 20-second window.
  ///
  /// [attemptId] is the same dispatch-attempt id an FCM push for this same
  /// offer would carry — passing it lets this share the FCM path's dedup
  /// guard and notification id, so a rider who gets both never hears two
  /// alerts for one offer.
  Future<void> showOfferDetectedAlert({
    required String attemptId,
    required String restaurantName,
  }) async {
    if (!Platform.isAndroid) return;
    if (!_claimAlert(attemptId)) return;
    await _showLocalAlert(
      _localNotifications,
      id: _offerNotificationId(attemptId),
      title: 'New delivery request',
      body: restaurantName.isEmpty
          ? 'Tap to view this delivery offer.'
          : 'Pickup from $restaurantName — tap to view.',
    );
  }

  void _handleTap(Map<String, dynamic> data) {
    if (data['type'] != 'NEW_DELIVERY_OFFER') return;
    unawaited(_openCurrentAssignment());
  }

  Future<void> _openCurrentAssignment() async {
    final container = _container;
    if (container == null) return;
    await Future.wait([
      container.read(dispatchOfferProvider.notifier).refresh(),
      container.read(activeOrderProvider.notifier).refresh(),
    ]);

    if (container.read(activeOrderProvider).valueOrNull != null) {
      if (Get.currentRoute != AppRoutes.activeOrder) {
        Get.toNamed(AppRoutes.activeOrder);
      }
      return;
    }

    final offer = container.read(dispatchOfferProvider).valueOrNull;
    if (offer != null &&
        !offer.isExpired &&
        Get.currentRoute != AppRoutes.incomingOffer) {
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
