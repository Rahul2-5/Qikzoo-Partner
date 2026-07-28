import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/earnings/earnings_models.dart';
import 'period_selector.dart';

const _positive = Color(0xFF20B957);
const _positiveSoft = Color(0xFFEAF9EF);

class TodayPerformanceHeader extends StatelessWidget {
  const TodayPerformanceHeader({super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RoundIconButton(
                icon: LucideIcons.arrowLeft,
                label: 'Go back',
                onTap: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.bike,
                        color: AppColors.primary, size: 26),
                    const SizedBox(width: 4),
                    RichText(
                      text: TextSpan(
                        style: AppTypography.h2.copyWith(
                          color: AppColors.primaryDark,
                          letterSpacing: -0.6,
                        ),
                        children: [
                          const TextSpan(text: 'Qikzoo'),
                          TextSpan(
                            text: ' PARTNER',
                            style: AppTypography.caption.copyWith(
                              color: _positive,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primarySoft,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: Text('RS',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _positive,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Earnings", style: AppTypography.h1),
                    const SizedBox(height: 3),
                    Text('25 July, Saturday', style: AppTypography.body),
                  ],
                ),
              ),
              const _OnlineBadge(),
            ],
          ),
        ],
      );
}

class TodayEarningsCard extends StatelessWidget {
  final double total;
  final double orderEarnings;
  final double incentives;
  final double tips;

  const TodayEarningsCard({
    super.key,
    required this.total,
    required this.orderEarnings,
    required this.incentives,
    required this.tips,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        label:
            "Today's total earnings ${CurrencyFormatter.rupeesPrecise(total)}",
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF17366F), Color(0xFF2457BF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332457BF),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -32,
                top: -48,
                child: _GlowCircle(
                    size: 132, color: Colors.white.withValues(alpha: 0.07)),
              ),
              Positioned(
                right: 30,
                bottom: 12,
                child: Icon(LucideIcons.wallet,
                    size: 52, color: Colors.white.withValues(alpha: 0.1)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Total Earnings',
                          style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: .88))),
                      const SizedBox(width: 6),
                      Icon(LucideIcons.info,
                          color: Colors.white.withValues(alpha: .72), size: 16),
                      const Spacer(),
                      const Icon(LucideIcons.chevronRight,
                          color: Colors.white, size: 24),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    CurrencyFormatter.rupeesPrecise(total),
                    style: AppTypography.display.copyWith(
                      color: Colors.white,
                      fontSize: 38,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(
                      color: Colors.white.withValues(alpha: .18), height: 1),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _EarningValue(
                            label: 'Order Earnings', amount: orderEarnings),
                      ),
                      _Divider(color: Colors.white.withValues(alpha: .18)),
                      Expanded(
                        child: _EarningValue(
                          label: 'Incentives',
                          amount: incentives,
                          amountColor: const Color(0xFF6EEB91),
                        ),
                      ),
                      _Divider(color: Colors.white.withValues(alpha: .18)),
                      Expanded(
                        child: _EarningValue(
                          label: 'Tips',
                          amount: tips,
                          amountColor: const Color(0xFFB6D2FF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class GigProgressCard extends StatelessWidget {
  const GigProgressCard({super.key});

  @override
  Widget build(BuildContext context) => _SurfaceCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gig Progress',
                      style: AppTypography.h2.copyWith(fontSize: 18)),
                  const SizedBox(height: AppSpacing.sm),
                  RichText(
                    text: TextSpan(
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: '6 / 8 ',
                          style: AppTypography.bodyMedium
                              .copyWith(color: _positive),
                        ),
                        const TextSpan(text: 'Orders Completed'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          child: const LinearProgressIndicator(
                            value: .75,
                            minHeight: 10,
                            backgroundColor: Color(0xFFE8ECF2),
                            valueColor: AlwaysStoppedAnimation(_positive),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('75%', style: AppTypography.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                  color: _positiveSoft, shape: BoxShape.circle),
              child: const Icon(LucideIcons.bike, size: 36, color: _positive),
            ),
          ],
        ),
      );
}

class TodayStatGrid extends StatelessWidget {
  const TodayStatGrid({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                width: cardWidth,
                child: const _PerformanceStatCard(
                  icon: LucideIcons.timer,
                  tint: Color(0xFFF1EBFF),
                  iconColor: Color(0xFF7958D9),
                  title: 'Online Hours',
                  value: '06h 15m',
                  caption: '1h 20m more than yesterday',
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: const _PerformanceStatCard(
                  icon: LucideIcons.shoppingBag,
                  tint: Color(0xFFFFF3E7),
                  iconColor: Color(0xFFE6892E),
                  title: 'Completed Orders',
                  value: '6',
                  caption: '2 more than yesterday',
                ),
              ),
            ],
          );
        },
      );
}

class TodayEarningsTrend extends StatelessWidget {
  final List<ChartBar> points;
  final double maxValue;
  final EarningsPeriod period;
  final ValueChanged<EarningsPeriod> onPeriodChanged;

  const TodayEarningsTrend({
    super.key,
    required this.points,
    required this.maxValue,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final peak = points.fold<ChartBar>(points.first,
        (current, point) => point.value > current.value ? point : current);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Earnings Trend', style: AppTypography.h2)),
              PeriodSelector(value: period, onChanged: onPeriodChanged),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 218,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const axisWidth = 38.0;
                return Row(
                  children: [
                    SizedBox(
                        width: axisWidth,
                        child: _TrendAxis(maxValue: maxValue)),
                    Expanded(
                      child: _LineChart(
                        points: points,
                        maxValue: maxValue,
                        peak: peak,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TodayBreakdownCard extends StatelessWidget {
  final List<EarningsCategory> categories;

  const TodayBreakdownCard({super.key, required this.categories});

  static const _icons = [
    LucideIcons.receipt,
    LucideIcons.gift,
    LucideIcons.mapPin,
    LucideIcons.trendingUp,
  ];
  static const _tints = [
    Color(0xFFFFF3E7),
    Color(0xFFEAF9EF),
    Color(0xFFEAF1FF),
    Color(0xFFFFEEF1),
  ];
  static const _iconColors = [
    Color(0xFFE6892E),
    _positive,
    AppColors.primary,
    Color(0xFFE16477),
  ];

  @override
  Widget build(BuildContext context) => _SurfaceCard(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Breakdown', style: AppTypography.h2)),
                Semantics(
                  button: true,
                  label: 'View earning details',
                  child: const _ViewDetailsButton(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var index = 0; index < categories.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _tints[index % _tints.length],
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(_icons[index % _icons.length],
                          size: 16,
                          color: _iconColors[index % _iconColors.length]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(categories[index].label,
                          style: AppTypography.body),
                    ),
                    Text(
                        CurrencyFormatter.rupeesPrecise(
                            categories[index].amount),
                        style: AppTypography.bodyMedium.copyWith(fontSize: 16)),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card + 2),
          border: Border.all(color: AppColors.border.withValues(alpha: .55)),
          boxShadow: AppShadows.control,
        ),
        child: child,
      );
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _positiveSoft,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _StatusDot(),
            const SizedBox(width: 7),
            Text('Online',
                style: AppTypography.bodyMedium.copyWith(color: _positive)),
          ],
        ),
      );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 11,
        height: 11,
        child: DecoratedBox(
          decoration: BoxDecoration(color: _positive, shape: BoxShape.circle),
        ),
      );
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RoundIconButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: 26,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: AppColors.textPrimary, size: 25),
          ),
        ),
      );
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _EarningValue extends StatelessWidget {
  final String label;
  final double amount;
  final Color? amountColor;
  const _EarningValue(
      {required this.label, required this.amount, this.amountColor});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: .74), fontSize: 11)),
          const SizedBox(height: 5),
          Text(CurrencyFormatter.rupeesPrecise(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: amountColor ?? Colors.white,
                fontSize: 15,
              )),
        ],
      );
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 42, color: color);
}

class _PerformanceStatCard extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String title;
  final String value;
  final String caption;
  const _PerformanceStatCard({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) => _SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(icon, size: 21, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
            const SizedBox(height: 3),
            Text(value, style: AppTypography.numericMd.copyWith(fontSize: 19)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.arrowUpRight,
                    size: 14, color: _positive),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(caption,
                      style: AppTypography.caption.copyWith(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      );
}

class _TrendAxis extends StatelessWidget {
  final double maxValue;
  const _TrendAxis({required this.maxValue});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final ratio in [1.0, .75, .5, .25, 0.0])
              Text(CurrencyFormatter.rupees(maxValue * ratio),
                  style: AppTypography.caption.copyWith(fontSize: 10)),
          ],
        ),
      );
}

class _LineChart extends StatelessWidget {
  final List<ChartBar> points;
  final double maxValue;
  final ChartBar peak;
  const _LineChart(
      {required this.points, required this.maxValue, required this.peak});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) => Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: _LineChartPainter(
                  points: points,
                  maxValue: maxValue,
                  progress: progress,
                  peak: peak,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final point in points)
                  Expanded(
                    child: Semantics(
                      label:
                          '${point.label}, ${CurrencyFormatter.rupeesPrecise(point.value)}',
                      child: Text(point.label,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(fontSize: 10)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}

class _LineChartPainter extends CustomPainter {
  final List<ChartBar> points;
  final double maxValue;
  final double progress;
  final ChartBar peak;
  _LineChartPainter({
    required this.points,
    required this.maxValue,
    required this.progress,
    required this.peak,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: .65)
      ..strokeWidth = 1;
    for (var index = 0; index < 5; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(
          Offset.zero.translate(0, y), Offset(size.width, y), gridPaint);
    }
    if (points.isEmpty) return;

    final chartPoints = <Offset>[];
    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * index / (points.length - 1);
      final ratio =
          (points[index].value / maxValue).clamp(0.0, 1.0).toDouble();
      chartPoints.add(Offset(x, size.height - size.height * ratio * progress));
    }

    final path = Path()..moveTo(chartPoints.first.dx, chartPoints.first.dy);
    for (var index = 1; index < chartPoints.length; index++) {
      final previous = chartPoints[index - 1];
      final current = chartPoints[index];
      path.cubicTo(
        (previous.dx + current.dx) / 2,
        previous.dy,
        (previous.dx + current.dx) / 2,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(chartPoints.last.dx, size.height)
      ..lineTo(chartPoints.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [AppColors.primary.withValues(alpha: .2), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var index = 0; index < chartPoints.length; index++) {
      final isPeak = points[index] == peak;
      canvas.drawCircle(
          chartPoints[index], isPeak ? 7 : 5, Paint()..color = Colors.white);
      canvas.drawCircle(chartPoints[index], isPeak ? 5 : 3.5,
          Paint()..color = isPeak ? _positive : AppColors.primary);
      if (isPeak) {
        _drawPeakLabel(canvas, chartPoints[index], points[index].value, size);
      }
    }
  }

  void _drawPeakLabel(Canvas canvas, Offset point, double value, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: CurrencyFormatter.rupees(value),
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const horizontalPadding = 8.0;
    final labelWidth = textPainter.width + horizontalPadding * 2;
    final x = math
        .min(math.max(0.0, point.dx - labelWidth / 2), size.width - labelWidth)
        .toDouble();
    final y = math.max(4.0, point.dy - 30).toDouble();
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, labelWidth, 22),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = AppColors.primary);
    textPainter.paint(canvas, Offset(x + horizontalPadding, y + 5));
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.progress != progress ||
      oldDelegate.peak != peak;
}

class _ViewDetailsButton extends StatelessWidget {
  const _ViewDetailsButton();
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('View Details',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontSize: 13,
                  )),
              const SizedBox(width: 2),
              const Icon(LucideIcons.chevronRight,
                  size: 17, color: AppColors.primary),
            ],
          ),
        ),
      );
}
