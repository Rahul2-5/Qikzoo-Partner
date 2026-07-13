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

  static bool _isRestaurantPhase(OrderStatus s) =>
      s == OrderStatus.accepted ||
      s == OrderStatus.navigatingToRestaurant ||
      s == OrderStatus.arrivedAtRestaurant;

  static String ctaLabelFor(OrderStatus s) {
    switch (s) {
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

  static bool isSwipeStatus(OrderStatus s) =>
      s == OrderStatus.arrivedAtRestaurant ||
      s == OrderStatus.arrivedAtCustomer;

  @override
  Widget build(BuildContext context) {
    final restaurant = _isRestaurantPhase(order.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          title: restaurant ? 'Pick up order' : 'Order picked up',
          subtitle: restaurant
              ? 'Go to the restaurant first'
              : 'Now deliver to the customer',
        ),
        const SizedBox(height: AppSpacing.md),
        OrderProgressTracker(status: order.status),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (restaurant)
                  _StatusBanner(
                    icon: LucideIcons.timer,
                    color: AppColors.secondary,
                    title: 'Pick up in ${order.etaMinutes} mins',
                    subtitle: 'Reach the restaurant asap to avoid delay',
                  )
                else
                  _StatusBanner(
                    icon: LucideIcons.checkCircle,
                    color: AppColors.success,
                    title:
                        'Order picked up at ${order.pickedUpAt ?? '10:25 AM'}',
                    subtitle:
                        '${order.restaurantName}, ${order.restaurantArea}',
                  ),
                const SizedBox(height: AppSpacing.md),
                CustomerLocationCard(
                  title:
                      restaurant ? 'Restaurant Location' : 'Customer Location',
                  address:
                      restaurant ? order.restaurantArea : order.dropAddress,
                  pincode: restaurant ? null : order.dropPincode,
                  etaLine:
                      '${order.distanceKm} km away · ${order.etaMinutes} mins · Light traffic',
                ),
                const SizedBox(height: AppSpacing.md),
                OrderDetailsCard(order: order),
                const SizedBox(height: AppSpacing.md),
                EarningsStrip(amount: order.amount),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _BottomAction(status: order.status, onAdvance: onAdvance),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.h1.copyWith(fontSize: 24)),
              Text(subtitle,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.helpCircle, size: 18),
          label: const Text('Help'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.bodyMedium.copyWith(color: color)),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.phone, size: 16),
            label: const Text('Call'),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.4)),
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
    return Row(
      children: [
        const _HelpIconButton(),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: PrimaryCtaButton(
            label: label,
            trailingIcon: LucideIcons.chevronsRight,
            onPressed: onAdvance,
          ),
        ),
      ],
    );
  }
}

class _HelpIconButton extends StatelessWidget {
  const _HelpIconButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: () {},
        tooltip: 'Help & Support',
        icon: const Icon(LucideIcons.headphones, color: AppColors.primary),
      ),
    );
  }
}
