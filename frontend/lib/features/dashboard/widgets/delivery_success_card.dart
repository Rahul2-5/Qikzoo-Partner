import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class DeliverySuccessCard extends StatelessWidget {
  final double amount;
  final String timestamp;

  const DeliverySuccessCard({
    super.key,
    required this.amount,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.successBg, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(LucideIcons.check, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order delivered successfully!',
                    style: AppTypography.bodyMedium),
                Text(timestamp, style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xs),
                Text('You earned', style: AppTypography.caption),
                Text(CurrencyFormatter.rupeesPrecise(amount),
                    style: AppTypography.numericMd
                        .copyWith(color: AppColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
