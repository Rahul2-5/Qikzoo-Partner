import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/device_tokens/device_tokens_repository.dart';
import '../../providers/orders/dispatch_offer_provider.dart';
import '../../providers/notifications/notifications_provider.dart';

class PushNotificationService {
  PushNotificationService(this._repository, this._ref);

  final DeviceTokensRepository _repository;
  final Ref _ref;

  Future<void> initialize() async {
    // Request permission
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    developer.log(
        'Partner notification permission status: ${settings.authorizationStatus}');

    // Handle token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        await registerToken(token);
      } catch (e) {
        developer.log('Failed to update refreshed token: $e');
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Received foreground message: ${message.data}');
      _ref.invalidate(notificationsProvider);
      if (message.data['type'] == 'NEW_DELIVERY_OFFER') {
        developer.log(
            'Foreground NEW_DELIVERY_OFFER received, refreshing dispatch offer...');
        _ref.read(dispatchOfferProvider.notifier).refresh();
      }
    });

    // Handle background notification clicks when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
          'App opened from background notification click: ${message.data}');
      _ref.invalidate(notificationsProvider);
      if (message.data['type'] == 'NEW_DELIVERY_OFFER') {
        _ref.read(dispatchOfferProvider.notifier).refresh();
      }
    });
  }

  Future<void> registerCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await registerToken(token);
      }
    } catch (e) {
      developer.log('Failed to get or register current FCM token: $e');
    }
  }

  Future<void> registerToken(String token) async {
    try {
      final platform = kIsWeb
          ? 'WEB'
          : Platform.isIOS
              ? 'IOS'
              : 'ANDROID';
      await _repository.register(token, platform);
      developer.log('FCM token registered successfully: $token ($platform)');
    } catch (e) {
      developer.log('Failed to register FCM token: $e');
    }
  }

  Future<void> removeToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _repository.remove(token);
        developer.log('FCM token unregistered from backend: $token');
      }
    } catch (e) {
      developer.log('Failed to remove FCM token: $e');
    }
  }
}

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService(
      ref.watch(deviceTokensRepositoryProvider), ref);
});
