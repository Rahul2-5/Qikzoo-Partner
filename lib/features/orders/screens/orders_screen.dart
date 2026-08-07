import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/order_preview_data.dart';
import '../../../models/dashboard/dashboard_stats_model.dart';
import '../../../models/orders/order_history_page_model.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../providers/orders/active_order_provider.dart';
import '../../../providers/orders/order_history_provider.dart';
import '../../../shared/widgets/chips/filter_chip_custom.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';
import '../widgets/order_history_list.dart';

/// The Orders tab's landing screen: a persistent "Active order" banner
/// (if the rider has one — recovers it via `activeOrderProvider`, backed
/// by `GET /rider/orders/current`) above the paginated
/// Active/Completed/Cancelled history tabs.
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
    final history = historyAsync.valueOrNull;
    final showOrderPreviews = ref.watch(showOrderPreviewProvider);
    final orderCount = history?.items.isEmpty == true && showOrderPreviews
        ? orderPreviewsFor(_filter).length
        : history?.total;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTabScaffold(
        currentIndex: 2,
        child: ResponsiveFrame(
          maxWidth: 640,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrdersHeader(
                orderCount: orderCount,
                availability: availability,
              ),
              const SizedBox(height: AppSpacing.sm),
              activeOrderAsync.maybeWhen(
                data: (order) => order == null
                    ? const SizedBox.shrink()
                    : _ActiveOrderBanner(
                        onTap: () => Get.toNamed(AppRoutes.activeOrder),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: OrderHistoryFilter.values.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final filter = OrderHistoryFilter.values[index];
                    return FilterChipCustom(
                      label: filter.label,
                      selected: _filter == filter,
                      onTap: () => setState(() => _filter = filter),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: OrderHistoryList(filter: _filter, onOpen: _openOrder),
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
  });

  final int? orderCount;
  final RiderAvailabilityStatus? availability;

  @override
  Widget build(BuildContext context) {
    final countLabel = orderCount == null
        ? 'Orders'
        : '$orderCount ${orderCount == 1 ? 'order' : 'orders'}';

    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              countLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h1.copyWith(fontSize: 22),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _AvailabilityPill(availability: availability),
      ],
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.availability});

  final RiderAvailabilityStatus? availability;

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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 112),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isOnline ? AppColors.successBg : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
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

class _ActiveOrderBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _ActiveOrderBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.bike, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'You have an order in progress',
                    style:
                        AppTypography.bodyMedium.copyWith(color: Colors.white),
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
