import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/order_list_entry.dart';
import '../../../shared/widgets/chips/status_chip.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';

class OrderListCard extends StatelessWidget {
  final OrderListEntry entry;
  final VoidCallback onTap;

  const OrderListCard({super.key, required this.entry, required this.onTap});

  ({Color color, Color bg, IconData icon, String word}) get _statusStyle =>
      switch (entry.status) {
        OrderListStatus.upcoming => (
            color: AppColors.success,
            bg: AppColors.successBg,
            icon: LucideIcons.history,
            word: 'Upcoming'
          ),
        OrderListStatus.completed => (
            color: AppColors.primary,
            bg: AppColors.primarySoft,
            icon: LucideIcons.check,
            word: 'Completed'
          ),
        OrderListStatus.cancelled => (
            color: AppColors.error,
            bg: AppColors.error.withValues(alpha: 0.12),
            icon: LucideIcons.x,
            word: 'Cancelled'
          ),
      };

  ({Color color, Color bg}) get _badgeStyle => switch (entry.badge) {
        OrderBadge.newOrder => (
            color: AppColors.warning,
            bg: AppColors.warningBg
          ),
        OrderBadge.delivered => (
            color: AppColors.success,
            bg: AppColors.successBg
          ),
        OrderBadge.cancelled => (
            color: AppColors.error,
            bg: AppColors.error.withValues(alpha: 0.12)
          ),
      };

  @override
  Widget build(BuildContext context) {
    final s = _statusStyle;
    final b = _badgeStyle;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppPressEffect(
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.control),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.control),
                boxShadow: AppShadows.control,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Rail(style: s, timeLabel: entry.timeLabel),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Order ID',
                                          style: AppTypography.caption),
                                      Text(entry.id,
                                          style: AppTypography.bodyMedium),
                                    ],
                                  ),
                                ),
                                StatusChip(
                                    label: entry.badge.label,
                                    color: b.color,
                                    background: b.bg),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                    CurrencyFormatter.rupeesPrecise(
                                        entry.amount),
                                    style: AppTypography.bodyMedium),
                                const Icon(LucideIcons.chevronRight,
                                    size: 16, color: AppColors.textSecondary),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                      color: AppColors.warning,
                                      shape: BoxShape.circle),
                                  child: const Icon(LucideIcons.store,
                                      color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.restaurantName,
                                          style: AppTypography.bodyMedium),
                                      Text(entry.restaurantArea,
                                          style: AppTypography.caption),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.mapPin,
                                    size: 18, color: AppColors.success),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(entry.dropAddress,
                                      style: AppTypography.caption),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${entry.distanceKm} km  •  ${entry.timeAwayLabel}',
                              style: AppTypography.caption,
                            ),
                            if (entry.status == OrderListStatus.upcoming) ...[
                              const SizedBox(height: AppSpacing.md),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton(
                                  onPressed: onTap,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.border),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.control)),
                                  ),
                                  child: const Text('View Details'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  final ({Color color, Color bg, IconData icon, String word}) style;
  final String timeLabel;

  const _Rail({required this.style, required this.timeLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.control),
          bottomLeft: Radius.circular(AppRadius.control),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(style.word,
              textAlign: TextAlign.center,
              style: AppTypography.caption
                  .copyWith(color: style.color, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(timeLabel,
              textAlign: TextAlign.center,
              style:
                  AppTypography.caption.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Icon(style.icon, size: 18, color: style.color),
        ],
      ),
    );
  }
}
