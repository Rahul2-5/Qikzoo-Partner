import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/feature_highlight_chip.dart';
import '../widgets/rider_hero_illustration.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isShort = constraints.maxHeight < 700;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: isShort ? AppSpacing.lg : AppSpacing.xl,
                          bottom: AppSpacing.lg,
                        ),
                        child: Column(
                          children: [
                            const _Wordmark(),
                            SizedBox(
                                height:
                                    isShort ? AppSpacing.lg : AppSpacing.xl),
                            RiderHeroIllustration(height: isShort ? 198 : 232),
                            SizedBox(
                                height:
                                    isShort ? AppSpacing.lg : AppSpacing.xl),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: AppTypography.display.copyWith(
                                  fontSize: isShort ? 27 : 30,
                                ),
                                children: const [
                                  TextSpan(text: 'Deliver more,\n'),
                                  TextSpan(
                                    text: 'Earn more',
                                    style:
                                        TextStyle(color: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                                height:
                                    isShort ? AppSpacing.lg : AppSpacing.xl),
                            const _FeatureRow(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PrimaryCtaButton(
                    label: 'Get Started',
                    trailingIcon: LucideIcons.arrowRight,
                    onPressed: () => Get.toNamed(AppRoutes.becomePartnerIntro),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _LoginCard(onTap: () => Get.toNamed(AppRoutes.otp)),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 130,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: AppSpacing.xs),
        RichText(
          text: TextSpan(
            style: AppTypography.bodyMedium.copyWith(letterSpacing: 1.2),
            children: const [
              TextSpan(
                  text: 'Delivery ',
                  style: TextStyle(color: AppColors.primary)),
              TextSpan(
                  text: 'Partner',
                  style: TextStyle(color: AppColors.secondary)),
            ],
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
    return const Row(
      children: [
        Expanded(
            child: FeatureHighlightChip(
                icon: LucideIcons.clock, label: 'Flexible\nhours')),
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
            label: 'Be your\nown boss',
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LoginCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already a partner? ', style: AppTypography.body),
              Text(
                'Login',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(LucideIcons.chevronRight,
                  size: 18, color: AppColors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
