import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/earnings/earnings_models.dart';
import '../../../providers/earnings/earnings_provider.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(earningsSummaryProvider);
    final historyAsync = ref.watch(earningsHistoryProvider);
    final today = DateTime.now();
    final weekStart = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - DateTime.monday));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekLabel =
        '${DateFormat('d MMM').format(weekStart)} - ${DateFormat('d MMM').format(weekEnd)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTabScaffold(
        currentIndex: 3,
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.calendarDays,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          weekLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Weekly Earnings Total
                  summaryAsync.when(
                    loading: () => Column(
                      children: [
                        LoadingSkeleton(
                          height: 38,
                          width: 140,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(height: 8),
                        LoadingSkeleton(
                          height: 14,
                          width: 90,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    error: (_, __) =>
                        const Center(child: Text("Error loading weekly total")),
                    data: (summary) => _WeeklyEarningsCard(
                      total: summary.thisWeek.total,
                      deliveries: summary.thisWeek.deliveries,
                      tips: summary.thisWeek.tips,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payouts Card Row
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: InkWell(
                      onTap: () => Get.toNamed(AppRoutes.payoutsDetail),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Icon(LucideIcons.landmark,
                                color: AppColors.primary, size: 22),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payouts & balance',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'View your available balance and payouts',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(LucideIcons.chevronRight,
                                color: AppColors.textSecondary, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // History Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Recent deliveries',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // "All Details" Filter Chip
                      ActionChip(
                        label: const Text('View all'),
                        onPressed: () =>
                            Get.toNamed(AppRoutes.earningsHistoryDetail),
                        backgroundColor: AppColors.successBg,
                        labelStyle: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        side: const BorderSide(color: AppColors.success),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  historyAsync.when(
                    loading: () => const PageLoadingShimmer(
                        padding: EdgeInsets.zero, itemCount: 3),
                    error: (error, _) => const Center(
                        child: Text("Error loading past deliveries")),
                    data: (page) => page.items.isEmpty
                        ? const _EmptyHistory()
                        : _EarningsHistoryList(entries: page.items),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyEarningsCard extends StatelessWidget {
  const _WeeklyEarningsCard({
    required this.total,
    required this.deliveries,
    required this.tips,
  });

  final double total;
  final int deliveries;
  final double tips;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This week',
              style: AppTypography.caption.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CurrencyFormatter.rupees(total),
              style: AppTypography.numericLg.copyWith(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Flexible(
                  child: _SummaryDetail(
                    icon: LucideIcons.packageCheck,
                    label: '$deliveries deliveries',
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Flexible(
                  child: _SummaryDetail(
                    icon: LucideIcons.heart,
                    label: '${CurrencyFormatter.rupees(tips)} tips',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _SummaryDetail extends StatelessWidget {
  const _SummaryDetail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: Colors.white),
            ),
          ),
        ],
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
    final dateLabel = deliveredAt == null
        ? ''
        : DateFormat('d MMM, h:mm a').format(deliveredAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
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
            child:
                const Icon(LucideIcons.checkCircle, color: AppColors.success),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.orderNumber ?? 'Delivery',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold),
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
              fontWeight: FontWeight.w900,
              fontSize: 16,
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
  Widget build(BuildContext context) => EmptyState(
        icon: LucideIcons.shoppingBag,
        title: 'No deliveries yet',
        message: 'Deliver your first order to start earning weekly payouts!',
        actionLabel: 'Go online now',
        onAction: () => Get.offAllNamed(AppRoutes.dashboard),
      );
}
