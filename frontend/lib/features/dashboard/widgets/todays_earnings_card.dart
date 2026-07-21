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
    return Semantics(
      label: "Today's earnings are ${CurrencyFormatter.rupeesPrecise(amount)}",
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 158),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF172253), Color(0xFF263B86)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sheet + 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x293F51B5),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -36,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned(
              right: 32,
              bottom: -52,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface.withValues(alpha: 0.05),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        border: Border.all(
                          color: AppColors.surface.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.wallet,
                        color: AppColors.surface,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Earnings",
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.surface,
                            ),
                          ),
                          Text(
                            'Updates after every delivery',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.surface.withValues(alpha: 0.68),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        'LIVE',
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFFB8C2FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  CurrencyFormatter.rupeesPrecise(amount),
                  style: AppTypography.numericLg.copyWith(
                    color: AppColors.surface,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
