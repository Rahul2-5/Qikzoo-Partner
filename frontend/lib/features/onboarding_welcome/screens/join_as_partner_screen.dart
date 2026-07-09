import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../widgets/benefit_list_item.dart';
import '../widgets/document_stack_illustration.dart';

class JoinAsPartnerScreen extends StatelessWidget {
  const JoinAsPartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              IconButtonCustom(icon: LucideIcons.arrowLeft, onPressed: () => Get.back()),
              const SizedBox(height: AppSpacing.lg),
              RichText(
                text: TextSpan(
                  style: AppTypography.h1.copyWith(fontSize: 26, height: 1.3),
                  children: const [
                    TextSpan(text: 'Join ', style: TextStyle(color: AppColors.textPrimary)),
                    TextSpan(text: 'QIKZOO', style: TextStyle(color: AppColors.secondary)),
                    TextSpan(text: ' as a\nDelivery Partner', style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const DocumentStackIllustration(),
              const SizedBox(height: AppSpacing.md),
              const BenefitListItem(
                icon: LucideIcons.star,
                label: 'Earn attractive incentives',
                color: AppColors.accent,
              ),
              const BenefitListItem(
                icon: LucideIcons.clock,
                label: 'Flexible working hours',
                color: AppColors.secondary,
              ),
              const BenefitListItem(
                icon: LucideIcons.barChart3,
                label: 'Weekly payouts',
                color: AppColors.primary,
              ),
              const BenefitListItem(
                icon: LucideIcons.headphones,
                label: 'Partner support 24/7',
                color: AppColors.success,
                showDivider: false,
              ),
              const Spacer(),
              PrimaryCtaButton(
                label: 'Continue',
                trailingIcon: LucideIcons.arrowRight,
                onPressed: () => Get.toNamed(AppRoutes.otp),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
