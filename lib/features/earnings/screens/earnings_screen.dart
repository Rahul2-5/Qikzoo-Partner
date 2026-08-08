import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/earnings/earnings_models.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';
import '../../../providers/notifications/notifications_provider.dart';
import '../widgets/today_performance_widgets.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  EarningsPeriod _period = EarningsPeriod.thisWeek;

  void _setPeriod(EarningsPeriod period) => setState(() => _period = period);

  @override
  Widget build(BuildContext context) {
    final summary = EarningsSummary.forPeriod(_period);
    final unreadNotificationCount = ref
        .watch(notificationsProvider)
        .valueOrNull
        ?.where((notification) => !notification.isRead)
        .length ??
        0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTabScaffold(
        currentIndex: 3,
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
                      AppStaggeredReveal(
                        index: 0,
                        child: TodayPerformanceHeader(
                          unreadNotificationCount: unreadNotificationCount,
                          onNotifications: () =>
                              Get.toNamed(AppRoutes.notifications),
                        ),
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
                      AppStaggeredReveal(
                        index: 2,
                        child: CashLimitAndDepositCard(
                          cashCollected: 1280,
                          cashLimit: 2000,
                          onDeposit: () => AppSnackBar.info(
                            context,
                            'Cash deposit instructions are available at your '
                            'assigned hub.',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const AppStaggeredReveal(
                        index: 3,
                        child: GigProgressCard(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const AppStaggeredReveal(
                        index: 4,
                        child: TodayStatGrid(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 5,
                        child: TodayEarningsTrend(
                          points: summary.bars,
                          maxValue: summary.maxBarValue,
                          period: _period,
                          onPeriodChanged: _setPeriod,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppStaggeredReveal(
                        index: 6,
                        child:
                            TodayBreakdownCard(categories: summary.categories),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
