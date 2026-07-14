import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/earnings/earnings_models.dart';
import 'period_selector.dart';

class EarningsHeader extends StatelessWidget {
  final EarningsPeriod period;
  final ValueChanged<EarningsPeriod> onPeriodChanged;

  const EarningsHeader({
    super.key,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final brand = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QIKZOO',
                  style: AppTypography.h2.copyWith(color: AppColors.primary)),
              Text('Delivery Partner', style: AppTypography.caption),
            ],
          );
          final selector =
              PeriodSelector(value: period, onChanged: onPeriodChanged);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                brand,
                const SizedBox(height: AppSpacing.sm),
                Align(alignment: Alignment.centerRight, child: selector),
              ] else
                Row(children: [brand, const Spacer(), selector]),
              const SizedBox(height: AppSpacing.md),
              Text('Earnings', style: AppTypography.h1),
            ],
          );
        },
      );
}
