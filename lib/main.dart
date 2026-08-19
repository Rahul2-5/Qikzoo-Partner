import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'core/location/rider_background_location_service.dart';
import 'core/push/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  _registerFontLicenses();
  await dotenv.load(fileName: '.env');
  RiderBackgroundLocationService.instance.initialize();

  // iOS has no GoogleService-Info.plist yet (see ios/Runner/Info.plist and
  // push_service.dart) — Firebase.initializeApp() would throw without it,
  // so this stays Android-only until real iOS config is supplied.
  if (Platform.isAndroid) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DeliveryPartnerApp(),
    ),
  );
  await PushService.instance.initialize(container);
}

void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Plus Jakarta Sans'],
      await rootBundle.loadString(
        'assets/fonts/OFL-PlusJakartaSans.txt',
      ),
    );
  });
}
