import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/rider_order_model.dart';
import '../../../providers/orders/order_detail_provider.dart';
import '../../../shared/widgets/chips/status_chip.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/error_widget_custom.dart';
import '../widgets/contact_actions.dart';
import '../widgets/order_status_timeline.dart';

/// Read-only order detail — reached from Orders History. Shows exactly
/// what the backend's `GET /rider/orders/:id` response provides; no
/// ordered-item list is shown because that endpoint doesn't return one.
class OrderDetailsScreen extends ConsumerWidget {
  final String riderOrderId;

  const OrderDetailsScreen({super.key, required this.riderOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(riderOrderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order details')),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 640,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: orderAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorWidgetCustom(
              message: error is ApiException
                  ? error.message
                  : 'Could not load this order.',
              onRetry: () =>
                  ref.read(orderDetailProvider(riderOrderId).notifier).refresh(),
            ),
            data: (order) => RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: () =>
                  ref.read(orderDetailProvider(riderOrderId).notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                children: [
                  _Header(order: order),
                  const SizedBox(height: AppSpacing.md),
                  ContactCard(
                    title: 'Restaurant',
                    name: order.restaurant.name,
                    address: order.restaurant.address,
                    landmark: order.restaurant.landmark,
                    phone: order.restaurant.phone,
                    latitude: order.restaurant.latitude,
                    longitude: order.restaurant.longitude,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ContactCard(
                    title: 'Customer',
                    name: order.order.customerName,
                    address: order.order.deliveryAddressLine ?? 'Address not available',
                    landmark: order.order.deliveryCity,
                    phone: order.order.customerPhone,
                    latitude: order.order.deliveryLat,
                    longitude: order.order.deliveryLng,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _EarningsCard(order: order),
                  if (order.status == RiderOrderStatus.cancelled &&
                      order.cancellationReason != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ReasonCard(
                      title: 'Cancellation reason',
                      reason: order.cancellationReason!,
                    ),
                  ],
                  if ((order.order.statusHistory ?? const []).isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text('Order timeline', style: AppTypography.h2),
                    const SizedBox(height: AppSpacing.sm),
                    OrderStatusTimeline(entries: order.order.statusHistory!),
                  ],
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

class _Header extends StatelessWidget {
  final RiderOrderModel order;

  const _Header({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order #${order.order.orderNumber}', style: AppTypography.h2),
              if (order.distanceKm != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${order.distanceKm!.toStringAsFixed(1)} km'
                  '${order.etaMinutes != null ? ' · ${order.etaMinutes!.round()} min' : ''}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        StatusChip(
          label: order.status.label,
          color: AppColors.secondary,
          background: AppColors.secondary.withValues(alpha: 0.12),
        ),
      ],
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final RiderOrderModel order;

  const _EarningsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final delivered = order.status == RiderOrderStatus.delivered;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery earnings', style: AppTypography.body),
              Text(
                delivered
                    ? CurrencyFormatter.rupees(order.earningsPaise / 100.0)
                    : '—',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
          if (order.tipsPaise > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tip', style: AppTypography.body),
                Text(CurrencyFormatter.rupees(order.tipsPaise / 100.0),
                    style: AppTypography.bodyMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  final String title;
  final String reason;

  const _ReasonCard({required this.title, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(reason, style: AppTypography.body),
        ],
      ),
    );
  }
}
