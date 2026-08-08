import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
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
    final customerName = order.order.customerName.trim().isEmpty
        ? 'Delivery customer'
        : order.order.customerName;
    final zone = _shortLocation(
      order.order.deliveryAddressLine,
      order.order.deliveryCity,
    );
    final time = DateFormat('h:mm a').format(order.assignedAt.toLocal());

    return AppPressEffect(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.55)),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderIdentity(order: order, time: time, visual: visual),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusBadge(visual: visual),
                          const Spacer(),
                          Text(
                            CurrencyFormatter.rupees(order.earningsPaise / 100),
                            style: AppTypography.numericMd.copyWith(
                              color: visual.color,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.moreVertical,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _OrderDetailLine(
                        icon: LucideIcons.mapPin,
                        label: zone.isEmpty ? 'Delivery location' : zone,
                      ),
                      const SizedBox(height: 3),
                      _OrderDetailLine(
                        icon: LucideIcons.store,
                        label: order.restaurant.name ?? 'Restaurant order',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _OrderMeta(
                                visual: visual, distanceKm: order.distanceKm),
                          ),
                          const SizedBox(width: 8),
                          _OrderAction(visual: visual, onTap: onTap),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderIdentity extends StatelessWidget {
  const _OrderIdentity({
    required this.order,
    required this.time,
    required this.visual,
  });

  final RiderOrderModel order;
  final String time;
  final _OrderVisual visual;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 60,
        child: Column(
          children: [
            Container(
              height: 62,
              width: 60,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: visual.background,
                borderRadius: BorderRadius.circular(AppRadius.control + 4),
              ),
              child: Image.asset(visual.asset, fit: BoxFit.contain),
            ),
            const SizedBox(height: 4),
            Text(
              '#${order.order.orderNumber.replaceFirst('QK-', '')}',
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(time, style: AppTypography.caption.copyWith(fontSize: 10)),
          ],
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.visual});

  final _OrderVisual visual;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: visual.background,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Text(
          visual.label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: visual.color,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      );
}

class _OrderDetailLine extends StatelessWidget {
  const _OrderDetailLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(fontSize: 11),
            ),
          ),
        ],
      );
}

class _OrderMeta extends StatelessWidget {
  const _OrderMeta({required this.visual, required this.distanceKm});

  final _OrderVisual visual;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) => Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: visual.background,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.shoppingBag, size: 15, color: visual.color),
            const SizedBox(width: 6),
            Text(
              'Order',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            if (distanceKm != null) ...[
              const SizedBox(width: 8),
              Icon(LucideIcons.map, size: 14, color: visual.color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${distanceKm!.toStringAsFixed(1)} km',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

class _OrderAction extends StatelessWidget {
  const _OrderAction({required this.visual, required this.onTap});

  final _OrderVisual visual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: visual.isActive ? visual.color : AppColors.surface,
              border: Border.all(color: visual.color),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            alignment: Alignment.center,
            child: Text(
              visual.isActive ? 'Open order' : 'View details',
              style: AppTypography.caption.copyWith(
                color: visual.isActive ? Colors.white : visual.color,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ),
      );
}

class _OrderVisual {
  const _OrderVisual({
    required this.label,
    required this.color,
    required this.background,
    required this.asset,
    required this.isActive,
  });

  final String label;
  final Color color;
  final Color background;
  final String asset;
  final bool isActive;

  factory _OrderVisual.fromStatus(RiderOrderStatus status) => switch (status) {
        RiderOrderStatus.delivered => _OrderVisual(
            label: 'Completed',
            color: AppColors.success,
            background: AppColors.successBg,
            asset: 'assets/images/orders/order_bag_delivered_3d.png',
            isActive: false,
          ),
        RiderOrderStatus.cancelled => _OrderVisual(
            label: 'Cancelled',
            color: AppColors.error,
            background: AppColors.error.withValues(alpha: 0.11),
            asset: 'assets/images/orders/order_bag_cancelled_3d.png',
            isActive: false,
          ),
        RiderOrderStatus.assigned => _OrderVisual(
            label: 'New',
            color: AppColors.warning,
            background: AppColors.warningBg,
            asset: 'assets/images/orders/order_bag_new_3d.png',
            isActive: true,
          ),
        _ => _OrderVisual(
            label: 'Ongoing',
            color: AppColors.success,
            background: AppColors.successBg,
            asset: 'assets/images/orders/order_bag_active_3d.png',
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
