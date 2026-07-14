import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/earnings/earnings_models.dart';

class NextPayoutCard extends StatelessWidget {
  final PayoutInfo payout;

  const NextPayoutCard({super.key, required this.payout});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: const Icon(LucideIcons.landmark, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next Payout', style: AppTypography.bodyMedium),
                Text('Transfers to your account', style: AppTypography.caption),
                const SizedBox(height: 2),
                Text('${payout.bankName} ····${payout.maskedAccount}',
                    style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(CurrencyFormatter.rupeesPrecise(payout.amount),
                  style: AppTypography.numericMd
                      .copyWith(color: AppColors.primary)),
              Text(payout.date, style: AppTypography.caption),
            ],
          ),
        ]),
      );
}
