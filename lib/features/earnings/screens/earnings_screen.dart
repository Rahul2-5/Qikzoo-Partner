import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/earnings/earnings_models.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';
import '../../../shared/widgets/navigation/app_bottom_nav.dart';
import '../widgets/today_performance_widgets.dart';

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppStaggeredReveal(
                        index: 0,
                        child: TodayPerformanceHeader(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 1,
                        child: TodayEarningsCard(
                          total: summary.total,
                          orderEarnings: summary.categories.first.amount,
                          incentives: summary.categories[1].amount,
                          tips: summary.categories[2].amount +
                              summary.categories[3].amount,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const AppStaggeredReveal(
                        index: 2,
                        child: GigProgressCard(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const AppStaggeredReveal(
                        index: 3,
                        child: TodayStatGrid(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 4,
                        child: TodayEarningsTrend(
                          points: summary.bars,
                          maxValue: summary.maxBarValue,
                          period: _period,
                          onPeriodChanged: _setPeriod,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 5,
                        child:
                            TodayBreakdownCard(categories: summary.categories),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              const AppBottomNav(currentIndex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
