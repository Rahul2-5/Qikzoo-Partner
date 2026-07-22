import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The fixed rider onboarding journey, display-only. Each phase of this
/// project implements one step; this widget never gates navigation and
/// never reflects live backend section status — it only orients the rider
/// within the overall journey while later steps remain unbuilt.
const onboardingStepLabels = [
  'Personal Details',
  'Address',
  'KYC',
  'Vehicle',
  'Bank',
  'Review',
];

class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;

  const OnboardingProgressBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < onboardingStepLabels.length; i++) ...[
              _StepChip(
                label: onboardingStepLabels[i],
                isCompleted: i < currentStep,
                isCurrent: i == currentStep,
              ),
              if (i != onboardingStepLabels.length - 1)
                Container(
                  width: 16,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color:
                      i < currentStep ? AppColors.secondary : AppColors.border,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isCurrent;

  const _StepChip({
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isCurrent
          ? '$label, current step'
          : (isCompleted ? '$label, completed' : label),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.secondaryBg
              : (isCompleted ? AppColors.successBg : AppColors.surface),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: isCurrent
                ? AppColors.secondary
                : (isCompleted ? AppColors.success : AppColors.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCompleted) ...[
              const Icon(
                LucideIcons.checkCircle2,
                size: 14,
                color: AppColors.success,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isCurrent
                    ? AppColors.secondary
                    : (isCompleted
                        ? AppColors.success
                        : AppColors.textSecondary),
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 4),
              Text(
                'Current',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
