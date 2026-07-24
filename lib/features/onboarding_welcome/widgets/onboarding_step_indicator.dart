import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class OnboardingStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $currentStep of $totalSteps',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 1; index <= totalSteps; index++) ...[
              AnimatedContainer(
                duration: AppMotion.duration(context, AppMotion.standard),
                curve: AppMotion.enter,
                width: index == currentStep ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: index <= currentStep
                      ? AppColors.secondary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
              ),
              if (index != totalSteps) const SizedBox(width: AppSpacing.xs),
            ],
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$currentStep/$totalSteps',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
