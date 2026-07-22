import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/authentication/auth_flow.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';
import '../widgets/feature_highlight_chip.dart';
import '../widgets/onboarding_step_indicator.dart';
import '../widgets/rider_hero_illustration.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F5FF), AppColors.background],
            stops: [0, 0.45],
          ),
        ),
        child: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 520,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 760;

                return Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    const AppStaggeredReveal(
                      index: 0,
                      child: _WelcomeTopBar(),
                    ),
                    SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            AppStaggeredReveal(
                              index: 1,
                              child: RiderHeroIllustration(
                                height: isCompact ? 228 : 272,
                              ),
                            ),
                            SizedBox(
                              height: isCompact ? AppSpacing.md : AppSpacing.lg,
                            ),
                            const AppStaggeredReveal(
                              index: 2,
                              child: _WelcomeCopy(),
                            ),
                            SizedBox(
                              height: isCompact ? AppSpacing.lg : AppSpacing.xl,
                            ),
                            const AppStaggeredReveal(
                              index: 3,
                              child: _FeatureRow(),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                    AppStaggeredReveal(
                      index: 4,
                      child: _WelcomeActions(
                        onGetStarted: () =>
                            Get.toNamed(AppRoutes.partnerBenefits),
                        onLogin: () => Get.toNamed(
                          authFlowRoute(AppRoutes.otp, AuthFlow.login),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeTopBar extends StatelessWidget {
  const _WelcomeTopBar();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _Wordmark()),
        SizedBox(width: AppSpacing.md),
        OnboardingStepIndicator(currentStep: 1, totalSteps: 2),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Qikzoo Partner',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.ctaGradient,
              ),
              borderRadius: BorderRadius.circular(AppRadius.control),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Text(
              'Q',
              style: AppTypography.h2.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QIKZOO',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'PARTNER',
                style: AppTypography.caption.copyWith(
                  color: AppColors.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).height < 760;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 4,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            'WORK ON YOUR TERMS',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.25,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.display.copyWith(
                fontSize: isCompact ? 29 : 33,
              ),
              children: const [
                TextSpan(text: 'Deliver more.\n'),
                TextSpan(
                  text: 'Earn on your terms.',
                  style: TextStyle(color: AppColors.secondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Text(
            'Choose your hours, make every trip count, and grow with Qikzoo.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'BUILT AROUND YOUR DAY',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.05,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        const Row(
          children: [
            Expanded(
              child: FeatureHighlightChip(
                icon: LucideIcons.clock3,
                label: 'Flexible\nhours',
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FeatureHighlightChip(
                icon: LucideIcons.wallet,
                label: 'Weekly\npayouts',
                color: AppColors.accent,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FeatureHighlightChip(
                icon: LucideIcons.trendingUp,
                label: 'More earning\ncontrol',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const _WelcomeActions({
    required this.onGetStarted,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PrimaryCtaButton(
          label: 'Start earning with Qikzoo',
          trailingIcon: LucideIcons.arrowRight,
          onPressed: onGetStarted,
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          button: true,
          label: 'Already a partner? Log in',
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: onLogin,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: Text.rich(
                TextSpan(
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  children: const [
                    TextSpan(text: 'Already a partner?  '),
                    TextSpan(
                      text: 'Log in',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
