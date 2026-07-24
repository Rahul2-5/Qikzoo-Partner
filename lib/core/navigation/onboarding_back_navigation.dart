import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Pops an onboarding screen when it was pushed in the current session.
/// Resumed onboarding starts after Splash has replaced the route stack, so a
/// logical predecessor is used when there is no route to pop.
Future<void> popOnboardingOrGoTo(
  BuildContext context,
  String fallbackRoute,
) async {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }

  Get.offNamed(fallbackRoute);
}
