import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/order_model.dart';

class OrderProgressTracker extends StatelessWidget {
  final OrderStatus status;

  const OrderProgressTracker({super.key, required this.status});

  /// 0 = at restaurant, 1 = on the way, 2 = delivered.
  static int stageForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
      case OrderStatus.navigatingToRestaurant:
      case OrderStatus.arrivedAtRestaurant:
        return 0;
      case OrderStatus.pickupConfirmed:
      case OrderStatus.navigatingToCustomer:
      case OrderStatus.arrivedAtCustomer:
        return 1;
      case OrderStatus.deliveryConfirmed:
      case OrderStatus.completed:
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = stageForStatus(status);
    const labels = ['Restaurant', 'On the way', 'Customer'];
    const subs = ['Pick up', '', 'Drop'];
    const icons = [LucideIcons.store, LucideIcons.bike, LucideIcons.mapPin];

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 3; i++) ...[
            _Node(
              icon: icons[i],
              label: labels[i],
              sub: subs[i],
              completed: i < stage,
              active: i == stage,
            ),
            if (i < 2)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: _Segment(filled: i < stage),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool completed;
  final bool active;

  const _Node({
    required this.icon,
    required this.label,
    required this.sub,
    required this.completed,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final on = completed || active;
    final circleColor = completed
        ? AppColors.success
        : (active ? AppColors.primary : AppColors.surfaceMuted);
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              boxShadow: on ? AppShadows.control : null,
            ),
            child: Icon(
              completed ? LucideIcons.check : icon,
              color: on ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: on ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (sub.isNotEmpty)
            Text(sub,
                textAlign: TextAlign.center, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final bool filled;
  const _Segment({required this.filled});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 3,
      decoration: BoxDecoration(
        color: filled ? AppColors.success : AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
