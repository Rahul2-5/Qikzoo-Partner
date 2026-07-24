import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/helpers/date_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/app_3d_illustration.dart';

/// Temporary payment destination until payment processing is connected.
/// It deliberately moves the rider to the review state rather than trying
/// to charge a payment method in the app.
class PaymentComingSoonScreen extends StatefulWidget {
  final Duration redirectDelay;

  const PaymentComingSoonScreen({
    super.key,
    this.redirectDelay = const Duration(seconds: 2),
  });

  @override
  State<PaymentComingSoonScreen> createState() =>
      _PaymentComingSoonScreenState();
}

class _PaymentComingSoonScreenState extends State<PaymentComingSoonScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.redirectDelay, () {
      if (mounted) Get.offNamed(AppRoutes.applicationUnderReview);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const App3dIllustration(
                    assetPath: AppAssets.welcomeKit3d,
                    semanticLabel: 'Welcome kit payment coming soon',
                    size: 180,
                    glowColor: AppColors.secondary,
                    fallbackIcon: LucideIcons.clock,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Payment Gateway Coming Soon',
                    textAlign: TextAlign.center,
                    style: AppTypography.h1.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'You can continue with your application while we finish setting up secure payments.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The terminal state shown after a rider completes the welcome-kit step.
class ApplicationUnderReviewScreen extends StatelessWidget {
  final DateTime submittedAt;

  ApplicationUnderReviewScreen({
    super.key,
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 520,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.hourglass,
                        color: AppColors.secondary,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Application under review',
                      textAlign: TextAlign.center,
                      style: AppTypography.h1.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      "We're verifying your details. This usually takes 24-48 hours.",
                      textAlign: TextAlign.center,
                      style: AppTypography.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Submitted on ${DateHelper.formatShort(submittedAt)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryCtaButton(
                      label: 'View application status',
                      trailingIcon: LucideIcons.arrowRight,
                      onPressed: () =>
                          Get.offAllNamed(AppRoutes.verificationStatus),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(
  name: 'Payment coming soon',
  group: 'Partner registration',
  size: Size(390, 844),
)
Widget paymentComingSoonPreview() => GetMaterialApp(
      theme: AppTheme.light,
      home: const PaymentComingSoonScreen(redirectDelay: Duration(days: 1)),
    );

@Preview(
  name: 'Application under review',
  group: 'Partner registration',
  size: Size(390, 844),
)
Widget applicationUnderReviewPreview() => GetMaterialApp(
      theme: AppTheme.light,
      home: ApplicationUnderReviewScreen(submittedAt: DateTime(2026, 7, 23)),
    );
