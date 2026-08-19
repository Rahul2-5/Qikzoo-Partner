import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/rider_order_model.dart';
import '../../../providers/orders/order_detail_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/error_widget_custom.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
import '../widgets/contact_actions.dart';
import '../widgets/order_status_timeline.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final String riderOrderId;

  const OrderDetailsScreen({super.key, required this.riderOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(riderOrderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order details'),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: orderAsync.when(
          loading: () => const PageLoadingShimmer(
            padding: EdgeInsets.all(AppSpacing.md),
            itemCount: 4,
          ),
          error: (error, _) => ErrorWidgetCustom(
            message: error is ApiException
                ? error.message
                : 'Could not load this order.',
            onRetry: () =>
                ref.read(orderDetailProvider(riderOrderId).notifier).refresh(),
          ),
          data: (order) => Column(
            children: [
              Expanded(
                child: ResponsiveFrame(
                  maxWidth: 640,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  child: RefreshIndicator(
                    color: AppColors.secondary,
                    onRefresh: () => ref
                        .read(orderDetailProvider(riderOrderId).notifier)
                        .refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        // Order Header (ID, Date, Status Badge)
                        _OrderHeaderCard(order: order),
                        const SizedBox(height: 12),

                        // Key Metrics Grid (Distance, Order Amount, Earning, Tip)
                        _OrderMetricsGrid(order: order),
                        const SizedBox(height: 12),

                        // Timing Milestones
                        _TimingMilestonesCard(order: order),
                        const SizedBox(height: 12),

                        // Cancellation Reason Alert (if cancelled)
                        if (order.status == RiderOrderStatus.cancelled) ...[
                          _CancellationAlertCard(order: order),
                          const SizedBox(height: 12),
                        ],

                        // Restaurant Card (Pickup)
                        ContactCard(
                          title: 'Pickup from (Restaurant)',
                          isRestaurant: true,
                          name: order.restaurant.name,
                          address: order.restaurant.address,
                          landmark: order.restaurant.landmark,
                          phone: order.restaurant.phone,
                          latitude: order.restaurant.latitude,
                          longitude: order.restaurant.longitude,
                          distanceKm: order.distanceKm,
                        ),
                        const SizedBox(height: 12),

                        // Customer Card (Delivery)
                        ContactCard(
                          title: 'Deliver to (Customer)',
                          isRestaurant: false,
                          name: order.order.customerName,
                          address: order.order.deliveryAddressLine ??
                              'Address not available',
                          landmark: order.order.deliveryCity,
                          phone: order.order.customerPhone,
                          latitude: order.order.deliveryLat,
                          longitude: order.order.deliveryLng,
                        ),
                        const SizedBox(height: 12),

                        // Customer Instruction Note
                        if (order.order.customerNote != null &&
                            order.order.customerNote!.trim().isNotEmpty) ...[
                          _CustomerNoteCard(note: order.order.customerNote!),
                          const SizedBox(height: 12),
                        ],

                        // Order Items Checklist
                        if (order.order.items.isNotEmpty) ...[
                          _OrderItemsCard(items: order.order.items),
                          const SizedBox(height: 12),
                        ],

                        // Order Timeline
                        if ((order.order.statusHistory ?? const []).isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.border, width: 0.8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.history,
                                        size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text('Order Timeline',
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                OrderStatusTimeline(
                                    entries: order.order.statusHistory!),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Fixed Actions Bar
              _BottomActionBar(order: order),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// UI Components
// -----------------------------------------------------------------------------

class _OrderHeaderCard extends StatelessWidget {
  final RiderOrderModel order;

  const _OrderHeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final orderNum = order.order.orderNumber.trim().isNotEmpty
        ? order.order.orderNumber.trim()
        : order.id;
    final dateStr =
        DateFormat('dd MMM yyyy • hh:mm a').format(order.assignedAt);

    final statusColor = switch (order.status) {
      RiderOrderStatus.delivered => AppColors.success,
      RiderOrderStatus.cancelled => AppColors.error,
      _ => AppColors.primary,
    };

    final statusBg = switch (order.status) {
      RiderOrderStatus.delivered => AppColors.successBg,
      RiderOrderStatus.cancelled => AppColors.error.withValues(alpha: 0.1),
      _ => AppColors.primarySoft,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        '#$orderNum',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: orderNum));
                        AppSnackBar.success(context, 'Order ID copied.');
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(LucideIcons.copy,
                            size: 14, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  order.status.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(LucideIcons.calendar,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                dateStr,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderMetricsGrid extends StatelessWidget {
  final RiderOrderModel order;

  const _OrderMetricsGrid({required this.order});

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status == RiderOrderStatus.cancelled;
    final earningsText = isCancelled
        ? '₹0.00'
        : (order.earningsPaise > 0
            ? CurrencyFormatter.rupees(order.earningsPaise / 100.0)
            : '₹0.00');

    final distanceText = order.distanceKm != null
        ? '${order.distanceKm!.toStringAsFixed(1)} km'
        : '-- km';

    final tipText = order.tipsPaise > 0
        ? CurrencyFormatter.rupees(order.tipsPaise / 100.0)
        : '₹0.00';

    return Column(
      children: [
        // Prominent Earning Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCancelled ? AppColors.surface : AppColors.successBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCancelled
                  ? AppColors.border
                  : AppColors.success.withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? AppColors.surfaceMuted
                          : AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.wallet,
                      size: 18,
                      color: isCancelled
                          ? AppColors.textSecondary
                          : AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Earning',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCancelled
                              ? AppColors.textSecondary
                              : AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCancelled
                            ? 'Order was cancelled'
                            : (order.status == RiderOrderStatus.delivered
                                ? 'Credited to wallet'
                                : 'Estimated for this order'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                earningsText,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isCancelled
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Bottom Row: Trip Distance & Tip
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.mapPin,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trip Distance',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          distanceText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.heartHandshake,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Tip',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          tipText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: order.tipsPaise > 0
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimingMilestonesCard extends StatelessWidget {
  final RiderOrderModel order;

  const _TimingMilestonesCard({required this.order});

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TimeColumn(
            label: 'Assigned',
            time: _formatTime(order.assignedAt),
            isDone: true,
          ),
          const Icon(LucideIcons.arrowRight,
              size: 13, color: AppColors.textDisabled),
          _TimeColumn(
            label: 'Arrived',
            time: _formatTime(order.arrivedAt),
            isDone: order.arrivedAt != null,
          ),
          const Icon(LucideIcons.arrowRight,
              size: 13, color: AppColors.textDisabled),
          _TimeColumn(
            label: 'Picked Up',
            time: _formatTime(order.pickedUpAt),
            isDone: order.pickedUpAt != null,
          ),
          const Icon(LucideIcons.arrowRight,
              size: 13, color: AppColors.textDisabled),
          _TimeColumn(
            label: order.status == RiderOrderStatus.cancelled
                ? 'Cancelled'
                : 'Delivered',
            time: _formatTime(
                order.deliveredAt ?? order.cancelledAt),
            isDone: order.deliveredAt != null || order.cancelledAt != null,
          ),
        ],
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final String label;
  final String time;
  final bool isDone;

  const _TimeColumn({
    required this.label,
    required this.time,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: isDone ? AppColors.textSecondary : AppColors.textDisabled,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDone ? AppColors.textPrimary : AppColors.textDisabled,
          ),
        ),
      ],
    );
  }
}

class _CancellationAlertCard extends StatelessWidget {
  final RiderOrderModel order;

  const _CancellationAlertCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final reason = order.cancellationReason?.trim().isNotEmpty == true
        ? order.cancellationReason!.trim()
        : 'Order cancelled by customer or restaurant.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.alertCircle, size: 16, color: AppColors.error),
              SizedBox(width: 6),
              Text(
                'Cancellation Reason',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            reason,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerNoteCard extends StatelessWidget {
  final String note;

  const _CustomerNoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.messageSquare,
                  size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Delivery Instruction',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  final List<OrderItemModel> items;

  const _OrderItemsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.utensils,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Items (${items.length})',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              item.isVeg ? Colors.green : Colors.red,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.isVeg ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (item.price != null)
                      Text(
                        CurrencyFormatter.rupees(item.price!),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final RiderOrderModel order;

  const _BottomActionBar({required this.order});

  @override
  Widget build(BuildContext context) {
    final isActive = order.status != RiderOrderStatus.delivered &&
        order.status != RiderOrderStatus.cancelled;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Help / Support
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textPrimary,
              ),
              onPressed: () => Get.toNamed(AppRoutes.support),
              icon: const Icon(LucideIcons.headphones, size: 15),
              label: const Text(
                'Support',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Primary action (View Route if active, or Directions)
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (isActive) {
                  Get.toNamed(AppRoutes.activeOrder);
                } else if (order.order.deliveryLat != null &&
                    order.order.deliveryLng != null) {
                  launchMaps(context, order.order.deliveryLat!,
                      order.order.deliveryLng!);
                } else if (order.restaurant.latitude != 0 &&
                    order.restaurant.longitude != 0) {
                  launchMaps(context, order.restaurant.latitude,
                      order.restaurant.longitude);
                } else {
                  AppSnackBar.info(context, 'Location coordinates unavailable.');
                }
              },
              icon: Icon(
                isActive ? LucideIcons.bike : LucideIcons.mapPin,
                size: 16,
              ),
              label: Text(
                isActive ? 'Go to Active Order' : 'View Route Map',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
