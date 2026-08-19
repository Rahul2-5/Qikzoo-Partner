import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/authentication/auth_flow.dart';
import '../widgets/onboarding_page_shell.dart';

class EarningsOnboardingScreen extends StatelessWidget {
  const EarningsOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingPageShell(
      step: 3,
      title: 'Track & Earn More',
      description:
          'Track your earnings and incentives in real-time and grow your income.',
      image: AppAssets.earningsWallet3d,
      buttonLabel: 'Get Started',
      onNext: () => Get.toNamed(authFlowRoute(AppRoutes.otp, AuthFlow.signUp)),
    );
  }
}