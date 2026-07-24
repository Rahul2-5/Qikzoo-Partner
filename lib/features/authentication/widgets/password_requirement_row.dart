import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class PasswordRequirementRow extends StatelessWidget {
  final String label;
  final bool met;
  final bool showDivider;

  const PasswordRequirementRow({
    super.key,
    required this.label,
    required this.met,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                met ? LucideIcons.checkCircle2 : LucideIcons.circle,
                size: 20,
                color: met
                    ? AppColors.accent
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color:
                        met ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
              height: 1,
              color: AppColors.textSecondary.withValues(alpha: 0.12)),
      ],
    );
  }
}
