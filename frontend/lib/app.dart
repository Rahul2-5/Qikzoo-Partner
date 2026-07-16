import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/routes/app_page_transition.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_motion.dart';
import 'core/theme/app_theme.dart';

class DeliveryPartnerApp extends StatelessWidget {
  const DeliveryPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Qikzoo Partner',
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      customTransition: AppPageTransition(),
      transitionDuration: AppMotion.standard,
      debugShowCheckedModeBanner: false,
    );
  }
}
