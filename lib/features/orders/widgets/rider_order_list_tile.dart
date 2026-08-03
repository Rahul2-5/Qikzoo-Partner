import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/rider_order_model.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';

(Color, Color) _statusColors(RiderOrderStatus status) => switch (status) {
      RiderOrderStatus.delivered => (AppColors.success, AppColors.successBg),
      RiderOrderStatus.cancelled => (
          AppColors.error,
          AppColors.error.withValues(alpha: 0.12)
        ),
      _ => (AppColors.secondary, AppColors.secondary.withValues(alpha: 0.12)),
    };

class RiderOrderListTile extends StatelessWidget {
  final RiderOrderModel order;
  final VoidCallback onTap;

  const RiderOrderListTile(
      {super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (color, background) = _statusColors(order.status);
    final restaurantName =
        order.restaurant.name ?? 'Order #${order.order.orderNumber}';
    final restaurantAddress = _locationLabel(
      order.restaurant.address,
      order.restaurant.landmark,
    );
    final deliveryAddress = _locationLabel(
      order.order.deliveryAddressLine,
      [order.order.deliveryCity, order.order.deliveryPincode]
          .whereType<String>()
          .where((part) => part.trim().isNotEmpty)
          .join(', '),
    );
    final placedAt =
        DateFormat('d MMM, h:mm a').format(order.assignedAt.toLocal());

    return AppPressEffect(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.72)),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        CurrencyFormatter.rupees(order.earningsPaise / 100.0),
                        style: AppTypography.numericMd.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Order #${order.order.orderNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StopDetail(
                  icon: LucideIcons.store,
                  title: restaurantName,
                  distanceKm: order.distanceKm,
                  address: restaurantAddress,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    color: AppColors.border.withValues(alpha: 0.72),
                  ),
                ),
                _StopDetail(
                  icon: LucideIcons.mapPin,
                  title: order.order.customerName.isEmpty
                      ? 'Delivery location'
                      : order.order.customerName,
                  address: deliveryAddress,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        order.status.label,
                        style: AppTypography.caption.copyWith(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      placedAt,
                      style: AppTypography.caption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        'View details',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StopDetail extends StatelessWidget {
  const _StopDetail({
    required this.icon,
    required this.title,
    required this.address,
    this.distanceKm,
  });

  final IconData icon;
  final String title;
  final String address;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (distanceKm != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${distanceKm!.toStringAsFixed(1)} km',
                        style: AppTypography.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ],
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
}

String _locationLabel(String? primary, String? secondary) => [
      primary,
      secondary,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
