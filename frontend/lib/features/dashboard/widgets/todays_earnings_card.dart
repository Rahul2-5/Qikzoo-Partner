import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class TodaysEarningsCard extends StatelessWidget {
  final double amount;

  const TodaysEarningsCard({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2C3D8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Icon(LucideIcons.wallet, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Earnings",
                    style:
                        AppTypography.caption.copyWith(color: Colors.white70)),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.rupeesPrecise(amount),
                  style: AppTypography.numericLg.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.white70),
        ],
      ),
    );
  }
}
