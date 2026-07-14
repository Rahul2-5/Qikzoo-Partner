import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/earnings/earnings_models.dart';
import 'period_selector.dart';

class EarningsTrendChart extends StatelessWidget {
  final List<ChartBar> bars;
  final double maxValue;
  final EarningsPeriod period;
  final ValueChanged<EarningsPeriod> onPeriodChanged;

  const EarningsTrendChart({
    super.key,
    required this.bars,
    required this.maxValue,
    required this.period,
    required this.onPeriodChanged,
  });

  static const double _plotHeight = 150;

  @override
  Widget build(BuildContext context) {
    final peak = bars.fold<double>(0, (m, b) => b.value > m ? b.value : m);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final selector =
                PeriodSelector(value: period, onChanged: onPeriodChanged);
            if (constraints.maxWidth < 420) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Earnings Trend', style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.sm),
                  Align(alignment: Alignment.centerRight, child: selector),
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Earnings Trend', style: AppTypography.h2),
                selector,
              ],
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: _plotHeight + 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _YAxis(maxValue: maxValue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        bottom: 20,
                        child: CustomPaint(painter: _GridPainter(maxValue)),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final bar in bars)
                            Expanded(
                              child: _Bar(
                                bar: bar,
                                maxValue: maxValue,
                                plotHeight: _plotHeight,
                                highlighted: bar.value == peak,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YAxis extends StatelessWidget {
  final double maxValue;
  const _YAxis({required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final ticks = <double>[
      maxValue,
      maxValue * 0.75,
      maxValue * 0.5,
      maxValue * 0.25,
      0
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final t in ticks)
            Text(CurrencyFormatter.rupees(t),
                style: AppTypography.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final ChartBar bar;
  final double maxValue;
  final double plotHeight;
  final bool highlighted;

  const _Bar({
    required this.bar,
    required this.maxValue,
    required this.plotHeight,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final fraction =
        maxValue == 0 ? 0.0 : (bar.value / maxValue).clamp(0.0, 1.0);
    return Semantics(
      label: '${bar.label}, ${CurrencyFormatter.rupeesPrecise(bar.value)}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(CurrencyFormatter.rupees(bar.value),
              style: AppTypography.caption.copyWith(fontSize: 9)),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, t, child) => Container(
              width: 14,
              height: plotHeight * t,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.ctaGradient,
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: highlighted ? AppShadows.cta : null,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 14,
            child: Text(bar.label,
                style: AppTypography.caption.copyWith(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double maxValue;
  _GridPainter(this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.maxValue != maxValue;
}
