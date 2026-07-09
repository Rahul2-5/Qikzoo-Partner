import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class BenefitListItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool showDivider;

  const BenefitListItem({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.secondary,
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: AppTypography.body)),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: AppColors.textSecondary.withValues(alpha: 0.1)),
      ],
    );
  }
}
