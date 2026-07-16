import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/order_model.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../widgets/customer_location_card.dart';
import '../widgets/earnings_strip.dart';
import '../widgets/order_details_card.dart';
import '../widgets/order_progress_tracker.dart';
import '../widgets/swipe_action_button.dart';

class ActiveOrderView extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onAdvance;

  const ActiveOrderView({
    super.key,
    required this.order,
    required this.onAdvance,
  });

  static bool _isRestaurantPhase(OrderStatus status) =>
      status == OrderStatus.accepted ||
      status == OrderStatus.navigatingToRestaurant ||
      status == OrderStatus.arrivedAtRestaurant;

  static String ctaLabelFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return 'Navigate to Restaurant';
      case OrderStatus.navigatingToRestaurant:
        return 'Reached Restaurant';
      case OrderStatus.arrivedAtRestaurant:
        return 'Confirm Pickup';
      case OrderStatus.pickupConfirmed:
      case OrderStatus.navigatingToCustomer:
        return 'Reached Customer';
      case OrderStatus.arrivedAtCustomer:
        return 'Confirm Delivery';
      default:
        return 'Continue';
    }
  }

  static bool isSwipeStatus(OrderStatus status) =>
      status == OrderStatus.arrivedAtRestaurant ||
      status == OrderStatus.arrivedAtCustomer;

  @override
  Widget build(BuildContext context) {
    final restaurant = _isRestaurantPhase(order.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(order: order, restaurantPhase: restaurant),
        const SizedBox(height: AppSpacing.md),
        OrderProgressTracker(status: order.status),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useColumns = constraints.maxWidth >= 760;
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _OrderContent(
                  order: order,
                  restaurantPhase: restaurant,
                  useColumns: useColumns,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _BottomAction(
              status: order.status,
              onAdvance: onAdvance,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _OrderContent extends StatelessWidget {
  final OrderModel order;
  final bool restaurantPhase;
  final bool useColumns;

  const _OrderContent({
    required this.order,
    required this.restaurantPhase,
    required this.useColumns,
  });

  @override
  Widget build(BuildContext context) {
    final status = restaurantPhase
        ? _StatusBanner(
            icon: LucideIcons.timer,
            color: AppColors.secondary,
            title: 'Pick up in ${order.etaMinutes} mins',
            subtitle: 'Reach the restaurant on time to keep the order moving',
          )
        : _StatusBanner(
            icon: LucideIcons.checkCircle,
            color: AppColors.success,
            title: 'Picked up at ${order.pickedUpAt ?? '10:25 AM'}',
            subtitle: '${order.restaurantName}, ${order.restaurantArea}',
          );

    final location = CustomerLocationCard(
      title: restaurantPhase ? 'Restaurant Location' : 'Customer Location',
      address: restaurantPhase ? order.restaurantArea : order.dropAddress,
      pincode: restaurantPhase ? null : order.dropPincode,
      etaLine:
          '${order.distanceKm} km away · ${order.etaMinutes} mins · Light traffic',
    );
    final details = OrderDetailsCard(order: order);
    final earnings = EarningsStrip(amount: order.amount);

    if (useColumns) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              children: [
                status,
                const SizedBox(height: AppSpacing.md),
                location,
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                details,
                const SizedBox(height: AppSpacing.md),
                earnings,
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        status,
        const SizedBox(height: AppSpacing.md),
        location,
        const SizedBox(height: AppSpacing.md),
        details,
        const SizedBox(height: AppSpacing.md),
        earnings,
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final OrderModel order;
  final bool restaurantPhase;

  const _Header({required this.order, required this.restaurantPhase});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                          blurRadius: 7,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'ACTIVE DELIVERY  ·  ${order.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                restaurantPhase ? 'Pick up order' : 'Order picked up',
                style: AppTypography.h1.copyWith(fontSize: 25),
              ),
              Text(
                restaurantPhase
                    ? 'Head to the restaurant first'
                    : 'Next stop: the customer',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: () {},
              tooltip: 'Call',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.22)),
              ),
              icon: const Icon(LucideIcons.phone, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final OrderStatus status;
  final VoidCallback onAdvance;

  const _BottomAction({required this.status, required this.onAdvance});

  @override
  Widget build(BuildContext context) {
    final label = ActiveOrderView.ctaLabelFor(status);
    if (ActiveOrderView.isSwipeStatus(status)) {
      return SwipeActionButton(label: label, onConfirmed: onAdvance);
    }
    return PrimaryCtaButton(
      label: label,
      trailingIcon: LucideIcons.chevronsRight,
      onPressed: onAdvance,
    );
  }
}
