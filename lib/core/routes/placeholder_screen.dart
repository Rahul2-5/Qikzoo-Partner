import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../shared/widgets/buttons/primary_cta_button.dart';
import '../../shared/widgets/layout/responsive_frame.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String? nextRoute;

  const PlaceholderScreen({super.key, required this.title, this.nextRoute});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: const Icon(
                      LucideIcons.layoutDashboard,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(title,
                      style: AppTypography.h2, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'This section is being prepared.',
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  if (nextRoute != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryCtaButton(
                      label: 'Continue',
                      trailingIcon: LucideIcons.arrowRight,
                      onPressed: () => Get.toNamed(nextRoute!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
