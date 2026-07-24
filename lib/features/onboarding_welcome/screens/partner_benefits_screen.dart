import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/authentication/auth_flow.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/app_3d_illustration.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';
import '../widgets/onboarding_step_indicator.dart';

class PartnerBenefitsScreen extends StatelessWidget {
  const PartnerBenefitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1F3FF), AppColors.background],
            stops: [0, 0.46],
          ),
        ),
        child: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 520,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 760;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    const _BenefitsTopBar(),
                    SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppStaggeredReveal(
                              index: 0,
                              child: _BenefitsHeader(),
                            ),
                            SizedBox(
                              height: isCompact ? AppSpacing.md : AppSpacing.lg,
                            ),
                            AppStaggeredReveal(
                              index: 1,
                              child: _InsuranceSpotlight(compact: isCompact),
                            ),
                            SizedBox(
                              height: isCompact ? AppSpacing.md : AppSpacing.lg,
                            ),
                            const AppStaggeredReveal(
                              index: 2,
                              child: _EverydayBenefits(),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                    AppStaggeredReveal(
                      index: 3,
                      child: PrimaryCtaButton(
                        label: 'Get Started',
                        trailingIcon: LucideIcons.arrowRight,
                        onPressed: () => Get.toNamed(
                          authFlowRoute(AppRoutes.otp, AuthFlow.signUp),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
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

class _BenefitsTopBar extends StatelessWidget {
  const _BenefitsTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Go back',
          child: IconButtonCustom(
            icon: LucideIcons.arrowLeft,
            onPressed: () => Get.back(),
          ),
        ),
        const Spacer(),
        const OnboardingStepIndicator(currentStep: 2, totalSteps: 2),
      ],
    );
  }
}

class _BenefitsHeader extends StatelessWidget {
  const _BenefitsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WELCOME TO QIKZOO',
          style: AppTypography.caption.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        RichText(
          text: TextSpan(
            style: AppTypography.display.copyWith(fontSize: 29),
            children: const [
              TextSpan(text: 'Earn with freedom.\n'),
              TextSpan(
                text: 'Grow with support.',
                style: TextStyle(color: AppColors.secondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        Text(
          'Benefits designed to support you on the road and care for the people waiting at home.',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _InsuranceSpotlight extends StatelessWidget {
  const _InsuranceSpotlight({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: 'Medical and health insurance cover up to 15 lakh rupees.',
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: compact ? 194 : 210),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(AppRadius.sheet + 4),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(
                        color: AppColors.surface.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.heartPulse,
                          color: Color(0xFFAAB7FF),
                          size: 14,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'FAMILY COVER',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.surface,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.65,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Text(
                    'Medical & health insurance',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.surface,
                      fontSize: compact ? 17 : 18,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.32),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      'COVER UP TO ₹15 LAKH',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Protection for you and your family, wherever the road takes you.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.78),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: ExcludeSemantics(
                child: Transform.translate(
                  offset: const Offset(5, 4),
                  child: App3dIllustration(
                    assetPath: AppAssets.applicationSubmitted3d,
                    semanticLabel: 'Medical and health insurance protection',
                    size: compact ? 112 : 126,
                    glowColor: const Color(0xFFAAB7FF),
                    fallbackIcon: LucideIcons.shieldCheck,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EverydayBenefits extends StatelessWidget {
  const _EverydayBenefits();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More reasons to partner',
          style: AppTypography.h2.copyWith(fontSize: 17),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        const _BenefitTile(
          assetPath: AppAssets.partnerStatusOffline3d,
          fallbackIcon: LucideIcons.power,
          glowColor: AppColors.secondary,
          title: 'Flexible earning',
          description: 'Go online and earn when it works for your day.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const _BenefitTile(
          assetPath: AppAssets.orderSearch3d,
          fallbackIcon: LucideIcons.bike,
          glowColor: AppColors.accent,
          title: 'Nearby opportunities',
          description: 'Find delivery opportunities around your area.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const _BenefitTile(
          assetPath: AppAssets.welcomeKit3d,
          fallbackIcon: LucideIcons.packageCheck,
          glowColor: AppColors.primary,
          title: 'Weekly payouts & partner support',
          description: 'Predictable payouts, essential gear, and help 24/7.',
        ),
      ],
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.assetPath,
    required this.fallbackIcon,
    required this.glowColor,
    required this.title,
    required this.description,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final Color glowColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
        boxShadow: AppShadows.control,
      ),
      child: Row(
        children: [
          App3dIllustration(
            assetPath: assetPath,
            semanticLabel: title,
            size: 76,
            glowColor: glowColor,
            fallbackIcon: fallbackIcon,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF1FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.check,
              color: AppColors.secondary,
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(
  name: 'Partner benefits - phone',
  group: 'Onboarding',
  size: Size(390, 844),
)
Widget partnerBenefitsScreenPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const PartnerBenefitsScreen(),
  );
}
