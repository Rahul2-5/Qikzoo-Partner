import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/authentication/auth_flow.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/benefit_list_item.dart';
import '../widgets/document_stack_illustration.dart';
import '../widgets/onboarding_step_indicator.dart';

class JoinAsPartnerScreen extends StatelessWidget {
  const JoinAsPartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0FAF7), AppColors.background],
            stops: [0, 0.4],
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
                    const _JoinTopBar(),
                    SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _JoinHeader(),
                            SizedBox(
                              height: isCompact ? AppSpacing.md : AppSpacing.lg,
                            ),
                            _SetupHeroCard(compact: isCompact),
                            SizedBox(
                              height: isCompact ? AppSpacing.md : AppSpacing.lg,
                            ),
                            const _BenefitsPanel(),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                    const _SecureSetupNote(),
                    const SizedBox(height: AppSpacing.sm + 2),
                    PrimaryCtaButton(
                      label: 'Continue with mobile number',
                      trailingIcon: LucideIcons.arrowRight,
                      onPressed: () => Get.toNamed(
                        authFlowRoute(AppRoutes.otp, AuthFlow.signUp),
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

class _JoinTopBar extends StatelessWidget {
  const _JoinTopBar();

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
        const OnboardingStepIndicator(currentStep: 2),
      ],
    );
  }
}

class _JoinHeader extends StatelessWidget {
  const _JoinHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BECOME A QIKZOO PARTNER',
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
              TextSpan(text: 'A simple start to\n'),
              TextSpan(
                text: 'flexible earning.',
                style: TextStyle(color: AppColors.secondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        Text(
          'Create your partner profile, verify your details, and get ready to deliver.',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _SetupHeroCard extends StatelessWidget {
  final bool compact;

  const _SetupHeroCard({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Documents ready for secure partner verification',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        height: compact ? 178 : 210,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          0,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE4F8F1), Color(0xFFF1F4FC)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.sheet + 4),
          border: Border.all(color: AppColors.surface),
          boxShadow: AppShadows.card,
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: ExcludeSemantics(
                child: DocumentStackIllustration(
                  height: compact ? 156 : 186,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      color: AppColors.surface,
                      size: 14,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'GUIDED SETUP',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.surface,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitsPanel extends StatelessWidget {
  const _BenefitsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Built for your day',
            style: AppTypography.h2.copyWith(fontSize: 17),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Everything you need to stay in control.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const BenefitListItem(
            icon: LucideIcons.star,
            label: 'Attractive incentives',
            supportingText: 'More ways to make each shift count',
            color: AppColors.accent,
          ),
          const BenefitListItem(
            icon: LucideIcons.clock3,
            label: 'Flexible working hours',
            supportingText: 'Choose a schedule that works for you',
            color: AppColors.secondary,
          ),
          const BenefitListItem(
            icon: LucideIcons.wallet,
            label: 'Weekly payouts',
            supportingText: 'A clear, predictable payout cycle',
            color: AppColors.primary,
          ),
          const BenefitListItem(
            icon: LucideIcons.headphones,
            label: 'Partner support 24/7',
            supportingText: 'Help is available when you need it',
            color: AppColors.success,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _SecureSetupNote extends StatelessWidget {
  const _SecureSetupNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          LucideIcons.lock,
          size: 15,
          color: AppColors.secondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            'Secure, guided profile setup',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
