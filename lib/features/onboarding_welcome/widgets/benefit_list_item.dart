import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class BenefitListItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? supportingText;
  final Color color;
  final bool showDivider;

  const BenefitListItem({
    super.key,
    required this.icon,
    required this.label,
    this.supportingText,
    this.color = AppColors.secondary,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (supportingText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        supportingText!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                LucideIcons.checkCircle2,
                size: 18,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 60,
            color: AppColors.border.withValues(alpha: 0.75),
          ),
      ],
    );
  }
}
