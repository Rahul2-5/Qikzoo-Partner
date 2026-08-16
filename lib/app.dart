import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/routes/app_page_transition.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_motion.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/lifecycle/rider_polling_lifecycle_observer.dart';

class DeliveryPartnerApp extends StatelessWidget {
  const DeliveryPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const RiderPollingLifecycleObserver(
      child: _DeliveryPartnerMaterialApp(),
    );
  }
}

class _DeliveryPartnerMaterialApp extends StatelessWidget {
  const _DeliveryPartnerMaterialApp();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Qikzoo Delivery Partner',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      customTransition: AppPageTransition(),
      transitionDuration: AppMotion.standard,
      debugShowCheckedModeBanner: false,
    );
  }
}
