import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/authentication/auth_flow.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';

class PartnerBenefitsScreen extends StatelessWidget {
  const PartnerBenefitsScreen({
    super.key,
    this.showOnboardingControls = true,
  });

  final bool showOnboardingControls;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 480,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < 720;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTopBar(),
                          const SizedBox(height: AppSpacing.md),
                          _buildHeaderSection(isCompact),
                          const SizedBox(height: AppSpacing.md),
                          _buildInsuranceCard(isCompact),
                          const SizedBox(height: AppSpacing.lg),
                          _buildReasonsSection(isCompact),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomActions(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButtonCustom(
          icon: LucideIcons.arrowLeft,
          tooltip: 'Back',
          onPressed: () => Get.back(),
        ),
        const Spacer(),
        if (showOnboardingControls)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 14,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '2/2',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderSection(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'WELCOME TO QIKZOO',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Earn with freedom.\nGrow with support.',
          style: AppTypography.display.copyWith(
            color: const Color(0xFF162B4D),
            fontSize: isCompact ? 25 : 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        Text(
          'Benefits designed to support you on the road and care for the people waiting at home.',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildInsuranceCard(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.heart, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'FAMILY COVER',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Medical & health\ninsurance',
                  style: AppTypography.h2.copyWith(
                    color: Colors.white,
                    fontSize: isCompact ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'COVER UP TO ₹15 LAKH',
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF162B4D),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Protection for you and your family, wherever the road takes you.',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.clipboardCheck,
              color: Colors.white,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonsSection(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More reasons to partner',
          style: AppTypography.h2.copyWith(
            color: const Color(0xFF162B4D),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Built around the way you want to work.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildReasonTile(
          icon: LucideIcons.bike,
          title: 'Flexible earning',
          description: 'Go online and earn when it suits you.',
        ),
        const SizedBox(height: 8),
        _buildReasonTile(
          icon: LucideIcons.packageCheck,
          title: 'Instant orders',
          description: 'Receive delivery requests near you.',
        ),
        const SizedBox(height: 8),
        _buildReasonTile(
          icon: LucideIcons.shieldAlert,
          title: 'Accident coverage',
          description: 'Stay safe with round-the-clock trip insurance.',
        ),
      ],
    );
  }

  Widget _buildReasonTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF162B4D),
                  ),
                ),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.check,
              color: AppColors.success,
              size: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryCtaButton(
            label: 'Get Started',
            trailingIcon: LucideIcons.arrowRight,
            onPressed: () => Get.toNamed(
              authFlowRoute(AppRoutes.otp, AuthFlow.signUp),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.checkCircle2,
                size: 14,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'Takes only a few minutes to get started',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

@Preview(
  name: 'Benefits - phone',
  group: 'Onboarding',
  size: Size(390, 844),
)
Widget partnerBenefitsScreenPreview() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const PartnerBenefitsScreen(),
    );
