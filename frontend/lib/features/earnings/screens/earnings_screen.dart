import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/earnings/earnings_models.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';
import '../../../shared/widgets/navigation/app_bottom_nav.dart';
import '../widgets/earnings_breakdown_grid.dart';
import '../widgets/earnings_header.dart';
import '../widgets/earnings_history_list.dart';
import '../widgets/earnings_trend_chart.dart';
import '../widgets/next_payout_card.dart';
import '../widgets/total_earnings_card.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  EarningsPeriod _period = EarningsPeriod.thisWeek;

  void _setPeriod(EarningsPeriod period) => setState(() => _period = period);

  @override
  Widget build(BuildContext context) {
    final summary = EarningsSummary.forPeriod(_period);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppStaggeredReveal(
                        index: 0,
                        child: EarningsHeader(
                          period: _period,
                          onPeriodChanged: _setPeriod,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 1,
                        child: TotalEarningsCard(
                          total: summary.total,
                          deltaPercent: summary.deltaPercent,
                          comparisonLabel: _period.comparisonLabel,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 2,
                        child: EarningsBreakdownGrid(
                          categories: summary.categories,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 3,
                        child: EarningsTrendChart(
                          bars: summary.bars,
                          maxValue: summary.maxBarValue,
                          period: _period,
                          onPeriodChanged: _setPeriod,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 4,
                        child: EarningsHistoryList(history: summary.history),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 5,
                        child: NextPayoutCard(payout: summary.payout),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              const AppBottomNav(currentIndex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
