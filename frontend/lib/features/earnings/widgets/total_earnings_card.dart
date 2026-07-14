import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import 'delta_chip.dart';

class TotalEarningsCard extends StatelessWidget {
  final double total;
  final double deltaPercent;
  final String comparisonLabel;

  const TotalEarningsCard({
    super.key,
    required this.total,
    required this.deltaPercent,
    required this.comparisonLabel,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF2C3D8F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Earnings',
                    style:
                        AppTypography.caption.copyWith(color: Colors.white70)),
                const SizedBox(height: AppSpacing.xs),
                Text(CurrencyFormatter.rupeesPrecise(total),
                    style: AppTypography.display.copyWith(color: Colors.white)),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [
                  DeltaChip(percent: deltaPercent),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text('more than $comparisonLabel',
                        style: AppTypography.caption
                            .copyWith(color: Colors.white70)),
                  ),
                ]),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child:
                const Icon(LucideIcons.wallet, color: Colors.white, size: 28),
          ),
        ]),
      );
}
