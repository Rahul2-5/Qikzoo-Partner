import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/benefit_list_item.dart';
import '../widgets/document_stack_illustration.dart';

class JoinAsPartnerScreen extends StatelessWidget {
  const JoinAsPartnerScreen({super.key});

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  IconButtonCustom(
                      icon: LucideIcons.arrowLeft, onPressed: () => Get.back()),
                  SizedBox(height: isShort ? AppSpacing.md : AppSpacing.lg),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: AppTypography.display.copyWith(
                                  fontSize: isShort ? 25 : 28,
                                ),
                                children: const [
                                  TextSpan(
                                      text: 'Join ',
                                      style: TextStyle(
                                          color: AppColors.textPrimary)),
                                  TextSpan(
                                      text: 'QIKZOO',
                                      style: TextStyle(
                                          color: AppColors.secondary)),
                                  TextSpan(
                                    text: ' as a\nDelivery Partner',
                                    style:
                                        TextStyle(color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                                height:
                                    isShort ? AppSpacing.md : AppSpacing.lg),
                            Center(
                              child: DocumentStackIllustration(
                                  height: isShort ? 176 : 208),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const _BenefitsPanel(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PrimaryCtaButton(
                    label: 'Continue',
                    trailingIcon: LucideIcons.arrowRight,
                    onPressed: () => Get.toNamed(AppRoutes.otp),
                  ),
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

class _BenefitsPanel extends StatelessWidget {
  const _BenefitsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          BenefitListItem(
            icon: LucideIcons.star,
            label: 'Earn attractive incentives',
            color: AppColors.accent,
          ),
          BenefitListItem(
            icon: LucideIcons.clock,
            label: 'Flexible working hours',
            color: AppColors.secondary,
          ),
          BenefitListItem(
            icon: LucideIcons.barChart3,
            label: 'Weekly payouts',
            color: AppColors.primary,
          ),
          BenefitListItem(
            icon: LucideIcons.headphones,
            label: 'Partner support 24/7',
            color: AppColors.success,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}
