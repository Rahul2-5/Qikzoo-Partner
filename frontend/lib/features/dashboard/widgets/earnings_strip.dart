import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class EarningsStrip extends StatelessWidget {
  final double amount;

  const EarningsStrip({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surface,
            child: Icon(LucideIcons.wallet, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estimated Earning', style: AppTypography.caption),
                Text(CurrencyFormatter.rupeesPrecise(amount),
                    style: AppTypography.numericMd),
              ],
            ),
          ),
          Row(
            children: [
              Text('View detail',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.primary)),
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}
