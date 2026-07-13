import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class IncentiveProgressCard extends StatelessWidget {
  final int completed;
  final int target;
  final double bonus;

  const IncentiveProgressCard({
    super.key,
    required this.completed,
    required this.target,
    required this.bonus,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (target - completed).clamp(0, target);
    final progress = target == 0 ? 0.0 : (completed / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.target, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child:
                    Text('Incentive Challenge', style: AppTypography.bodyMedium),
              ),
              Text('$completed / $target', style: AppTypography.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$remaining deliveries away from ${CurrencyFormatter.rupees(bonus)} extra',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surface,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
