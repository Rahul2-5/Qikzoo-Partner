import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class EarningsBreakdownWidget extends StatelessWidget {
  final double base;
  final double distance;
  final double surge;
  final double tip;

  const EarningsBreakdownWidget({
    super.key,
    required this.base,
    required this.distance,
    required this.surge,
    required this.tip,
  });

  double get total => base + distance + surge + tip;

  Widget _row(String label, double value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.body),
            Text(CurrencyFormatter.rupees(value), style: AppTypography.bodyMedium),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row('Base fare', base),
        _row('Distance', distance),
        _row('Surge', surge),
        _row('Tip', tip),
        const Divider(color: AppColors.background, height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: AppTypography.h2),
            Text(CurrencyFormatter.rupees(total), style: AppTypography.numericMd),
          ],
        ),
      ],
    );
  }
}
