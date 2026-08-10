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
import '../../../models/dashboard/dashboard_stats_model.dart';
import '../../../models/orders/order_history_page_model.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../providers/notifications/notifications_provider.dart';
import '../../../providers/orders/active_order_provider.dart';
import '../../../providers/orders/order_history_provider.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';
import '../../../shared/widgets/navigation/partner_app_header.dart';
import '../widgets/order_history_list.dart';

/// The landing view for a rider's current and historical orders.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  OrderHistoryFilter _filter = OrderHistoryFilter.active;

  void _openOrder(String riderOrderId) {
    Get.toNamed(AppRoutes.orderDetails, arguments: riderOrderId);
  }

  @override
  Widget build(BuildContext context) {
    final activeOrderAsync = ref.watch(activeOrderProvider);
    final historyAsync = ref.watch(orderHistoryProvider(_filter));
    final availability =
        ref.watch(dashboardStatsProvider).valueOrNull?.availabilityStatus;
    final unreadNotificationCount = ref
            .watch(notificationsProvider)
            .valueOrNull
            ?.where((notification) => !notification.isRead)
            .length ??
        0;
    final history = historyAsync.valueOrNull;
    // A rider can hold only one active assignment. Keep the active tab and
    // its count tied to that single source of truth rather than to paginated
    // history, which can contain stale active rows while an order progresses.
    final activeOrder = activeOrderAsync.valueOrNull;
    final orderCount = _filter == OrderHistoryFilter.active
        ? (activeOrder != null ? 1 : 0)
        : history?.total;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTabScaffold(
        currentIndex: 2,
        child: ResponsiveFrame(
          // Keep dense order information readable on tablet and desktop
          // windows instead of stretching each card across the screen.
          maxWidth: 560,
          padding: const EdgeInsets.fromLTRB(
            12,
            AppSpacing.sm,
            12,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrdersHeader(
                orderCount: orderCount,
                availability: availability,
                unreadNotificationCount: unreadNotificationCount,
              ),
              const SizedBox(height: AppSpacing.md),
              activeOrderAsync.maybeWhen(
                data: (order) => order == null
                    ? const SizedBox.shrink()
                    : _ActiveOrderBanner(
                        onTap: () => Get.toNamed(AppRoutes.activeOrder),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: OrderHistoryFilter.values.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final filter = OrderHistoryFilter.values[index];
                    return _OrderFilterTab(
                      label: switch (filter) {
                        OrderHistoryFilter.active => 'Ongoing',
                        OrderHistoryFilter.completed => 'Completed',
                        OrderHistoryFilter.cancelled => 'Cancelled',
                      },
                      count: filter == _filter ? orderCount : null,
                      selected: _filter == filter,
                      onTap: () => setState(() => _filter = filter),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _filter == OrderHistoryFilter.active &&
                        activeOrder != null
                    ? const SizedBox.shrink()
                    : OrderHistoryList(filter: _filter, onOpen: _openOrder),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.orderCount,
    required this.availability,
    required this.unreadNotificationCount,
  });

  final int? orderCount;
  final RiderAvailabilityStatus? availability;
  final int unreadNotificationCount;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE, d MMM').format(DateTime.now());
    final countLabel = orderCount == null
        ? null
        : '$orderCount ${orderCount == 1 ? 'order' : 'orders'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PartnerAppHeader(
          unreadNotificationCount: unreadNotificationCount,
          onNotifications: () => Get.toNamed(AppRoutes.notifications),
          trailing: PartnerHeaderIconButton(
            icon: LucideIcons.helpCircle,
            label: 'Order help',
            onPressed: () => Get.toNamed(AppRoutes.support),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Orders', style: AppTypography.h1),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(date,
                          style: AppTypography.body
                              .copyWith(color: AppColors.textSecondary)),
                      if (countLabel != null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 7),
                          child: Text('•',
                              style: TextStyle(color: AppColors.textDisabled)),
                        ),
                        Text(countLabel, style: AppTypography.caption),
                      ],
                      const SizedBox(width: 2),
                      const Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PartnerHeaderIconButton(
              icon: LucideIcons.search,
              label: 'Search orders',
              onPressed: () {},
            ),
            const SizedBox(width: AppSpacing.sm),
            PartnerHeaderIconButton(
              icon: LucideIcons.slidersHorizontal,
              label: 'Filter orders',
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _AvailabilityPill(availability: availability, compact: true),
      ],
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.availability, this.compact = false});

  final RiderAvailabilityStatus? availability;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isOnline = availability?.isOnlineFacing ?? false;
    final label = availability == null
        ? 'Checking'
        : isOnline
            ? 'Online'
            : 'Offline';
    final color = isOnline ? AppColors.success : AppColors.textSecondary;

    return Semantics(
      label: 'Availability: $label',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 13,
          vertical: compact ? 6 : 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          boxShadow: AppShadows.control,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 7 : 9,
              height: compact ? 7 : 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: compact ? 6 : 8),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 14,
              ),
            ),
            SizedBox(width: compact ? 4 : 6),
            Icon(LucideIcons.chevronDown, size: compact ? 14 : 16),
          ],
        ),
      ),
    );
  }
}

class _OrderFilterTab extends StatelessWidget {
  const _OrderFilterTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: selected ? AppColors.secondary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primarySoft
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.caption.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class _ActiveOrderBanner extends StatelessWidget {
  const _ActiveOrderBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.ctaGradient),
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: AppShadows.cta,
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.navigation, color: Colors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'You have an order in progress',
                      style: AppTypography.bodyMedium
                          .copyWith(color: Colors.white),
                    ),
                  ),
                  const Icon(LucideIcons.arrowRight, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      );
}
