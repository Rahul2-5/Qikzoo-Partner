import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/earnings/earnings_models.dart';

class PeriodSelector extends StatelessWidget {
  final EarningsPeriod value;
  final ValueChanged<EarningsPeriod> onChanged;

  const PeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    return PopupMenuButton<EarningsPeriod>(
      onSelected: onChanged,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control)),
      itemBuilder: (context) => [
        for (final p in EarningsPeriod.values)
          PopupMenuItem(
            value: p,
            child: Text(p.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: p == value ? AppColors.primary : AppColors.textPrimary,
                )),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLargeText ? AppSpacing.sm : AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          boxShadow: AppShadows.control,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.calendar,
                size: 16, color: AppColors.primary),
            SizedBox(width: isLargeText ? AppSpacing.xs : AppSpacing.sm),
            Flexible(
              child: Text(
                value.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium,
              ),
            ),
            const Icon(LucideIcons.chevronDown,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
