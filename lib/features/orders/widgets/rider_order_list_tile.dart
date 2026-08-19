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

class RiderOrderListTile extends StatelessWidget {
  const RiderOrderListTile({
    super.key,
    required this.order,
    required this.onTap,
  });

  final RiderOrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _OrderVisual.fromStatus(order.status);
    final orderId = order.order.orderNumber.isNotEmpty
        ? order.order.orderNumber
        : '#${order.id.substring(0, 8)}';
    final dateFormatted =
        DateFormat('d MMM, h:mm a').format(order.assignedAt.toLocal());
    final restaurantName = order.restaurant.name?.trim().isNotEmpty == true
        ? order.restaurant.name!
        : 'Restaurant Partner';
    final customerName = order.order.customerName.trim().isNotEmpty
        ? order.order.customerName.trim()
        : 'Customer';
    final zone = _shortLocation(
      order.order.deliveryAddressLine,
      order.order.deliveryCity,
    );
    final distanceStr = order.distanceKm != null
        ? '${order.distanceKm!.toStringAsFixed(1)} km'
        : null;
    final isCancelled = order.status == RiderOrderStatus.cancelled;
    final earningStr = isCancelled
        ? '₹0.00'
        : CurrencyFormatter.rupees(order.earningsPaise / 100);

    return AppPressEffect(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Order ID • Date & Status Badge
                Row(
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                orderId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateFormatted,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(visual: visual),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle: Restaurant & Customer Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: visual.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.store,
                        size: 20,
                        color: visual.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  zone.isNotEmpty
                                      ? '$customerName • $zone'
                                      : customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 10),

                // Bottom Row: Distance • Earning • Action
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (distanceStr != null) ...[
                            const Icon(
                              LucideIcons.navigation,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              distanceStr,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Text(
                                '•',
                                style: TextStyle(color: AppColors.textDisabled),
                              ),
                            ),
                          ],
                          Text(
                            'Earn:',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              earningStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.numericMd.copyWith(
                                color: isCancelled
                                    ? AppColors.textSecondary
                                    : AppColors.success,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: visual.isActive
                            ? AppColors.primary
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        visual.isActive ? 'Open Order' : 'Details',
                        style: AppTypography.caption.copyWith(
                          color: visual.isActive
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.visual});

  final _OrderVisual visual;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: visual.background,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: visual.color.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          visual.label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: visual.color,
            fontWeight: FontWeight.w800,
            fontSize: 9.5,
          ),
        ),
      );
}

class _OrderVisual {
  const _OrderVisual({
    required this.label,
    required this.color,
    required this.background,
    required this.isActive,
  });

  final String label;
  final Color color;
  final Color background;
  final bool isActive;

  factory _OrderVisual.fromStatus(RiderOrderStatus status) => switch (status) {
        RiderOrderStatus.delivered => const _OrderVisual(
            label: 'Completed',
            color: AppColors.success,
            background: Color(0xFFDCFCE7),
            isActive: false,
          ),
        RiderOrderStatus.cancelled => const _OrderVisual(
            label: 'Cancelled',
            color: AppColors.error,
            background: Color(0xFFFEE2E2),
            isActive: false,
          ),
        RiderOrderStatus.assigned => const _OrderVisual(
            label: 'New',
            color: AppColors.warning,
            background: Color(0xFFFEF3C7),
            isActive: true,
          ),
        _ => const _OrderVisual(
            label: 'Active',
            color: AppColors.secondary,
            background: Color(0xFFFFEDD5),
            isActive: true,
          ),
      };
}

String _shortLocation(String? primary, String? city) {
  final normalized = primary?.trim() ?? '';
  if (normalized.isNotEmpty) {
    return normalized.split(',').first.trim();
  }
  return city?.trim() ?? '';
}
