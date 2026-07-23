import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/rider_order_model.dart';
import '../../../shared/widgets/chips/status_chip.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';

(Color, Color) _statusColors(RiderOrderStatus status) => switch (status) {
      RiderOrderStatus.delivered => (AppColors.success, AppColors.successBg),
      RiderOrderStatus.cancelled => (AppColors.error, AppColors.error.withValues(alpha: 0.12)),
      _ => (AppColors.secondary, AppColors.secondary.withValues(alpha: 0.12)),
    };

class RiderOrderListTile extends StatelessWidget {
  final RiderOrderModel order;
  final VoidCallback onTap;

  const RiderOrderListTile({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (color, background) = _statusColors(order.status);
    final dateLabel = DateFormat('d MMM, h:mm a').format(order.assignedAt.toLocal());

    return AppPressEffect(
      child: Material(
        color: AppColors.surface,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.restaurant.name ?? 'Order #${order.order.orderNumber}',
                        style: AppTypography.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusChip(label: order.status.label, color: color, background: background),
                  ],
                ),
                const SizedBox(height: 4),
                Text(dateLabel,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (order.distanceKm != null)
                      Text('${order.distanceKm!.toStringAsFixed(1)} km',
                          style: AppTypography.caption),
                    if (order.status == RiderOrderStatus.delivered)
                      Text(
                        CurrencyFormatter.rupees(order.earningsPaise / 100.0),
                        style: AppTypography.numericMd,
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
