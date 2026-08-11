import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/earnings/earnings_models.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../providers/earnings/earnings_provider.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/error_widget_custom.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
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
  EarningsPeriod _period = EarningsPeriod.today;

  void _setPeriod(EarningsPeriod period) => setState(() => _period = period);

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(earningsSummaryProvider);
    final historyAsync = ref.watch(earningsHistoryProvider);
    final isOnline = ref
            .watch(dashboardStatsProvider)
            .valueOrNull
            ?.availabilityStatus
            .isOnlineFacing ??
        false;
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
          child: RefreshIndicator(
            color: AppColors.secondary,
            onRefresh: () => Future.wait([
              ref.read(earningsSummaryProvider.notifier).refresh(),
              ref.read(earningsHistoryProvider.notifier).refresh(),
            ]),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppStaggeredReveal(
                    index: 0,
                    child: TodayPerformanceHeader(
                      unreadNotificationCount: unreadNotificationCount,
                      onNotifications: () => Get.toNamed(AppRoutes.notifications),
                      isOnline: isOnline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppStaggeredReveal(
                    index: 1,
                    child: _PeriodTabs(period: _period, onChanged: _setPeriod),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  summaryAsync.when(
                    loading: () => const LoadingSkeleton(height: 220),
                    error: (error, _) => ErrorWidgetCustom(
                      message: 'Could not load earnings.',
                      onRetry: () =>
                          ref.read(earningsSummaryProvider.notifier).refresh(),
                    ),
                    data: (summary) {
                      final bucket = summary.forPeriod(_period);
                      return AppStaggeredReveal(
                        index: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TodayEarningsCard(
                              total: bucket.total,
                              earnings: bucket.earnings,
                              tips: bucket.tips,
                              deliveries: bucket.deliveries,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TodayStatGrid(deliveries: bucket.deliveries),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppStaggeredReveal(
                    index: 3,
                    child: Text('Recent deliveries', style: AppTypography.h2),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  historyAsync.when(
                    loading: () => const PageLoadingShimmer(
                      padding: EdgeInsets.zero,
                      itemCount: 3,
                    ),
                    error: (error, _) => ErrorWidgetCustom(
                      message: 'Could not load your delivery history.',
                      onRetry: () =>
                          ref.read(earningsHistoryProvider.notifier).refresh(),
                    ),
                    data: (page) => page.items.isEmpty
                        ? const _EmptyHistory()
                        : _EarningsHistoryList(entries: page.items),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.period, required this.onChanged});

  final EarningsPeriod period;
  final ValueChanged<EarningsPeriod> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (final value in EarningsPeriod.values) ...[
            Expanded(
              child: _PeriodTab(
                label: value.label,
                selected: value == period,
                onTap: () => onChanged(value),
              ),
            ),
            if (value != EarningsPeriod.values.last)
              const SizedBox(width: AppSpacing.sm),
          ],
        ],
      );
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      );
}

class _EarningsHistoryList extends StatelessWidget {
  const _EarningsHistoryList({required this.entries});

  final List<EarningsHistoryEntry> entries;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final entry in entries) ...[
            _EarningsHistoryTile(entry: entry),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      );
}

class _EarningsHistoryTile extends StatelessWidget {
  const _EarningsHistoryTile({required this.entry});

  final EarningsHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final deliveredAt = entry.deliveredAt;
    final dateLabel =
        deliveredAt == null ? '' : DateFormat('d MMM, h:mm a').format(deliveredAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: const Icon(LucideIcons.checkCircle, color: AppColors.success),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.orderNumber ?? 'Delivery',
                  style: AppTypography.bodyMedium,
                ),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(dateLabel,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          Text(
            CurrencyFormatter.rupees(entry.total),
            style: AppTypography.numericMd.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => const EmptyState(
        icon: LucideIcons.wallet,
        title: 'No earnings yet',
        message: 'Completed deliveries will show up here with what you earned.',
      );
}
