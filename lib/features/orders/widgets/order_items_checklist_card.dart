import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/rider_order_model.dart';

class OrderItemsChecklistCard extends StatelessWidget {
  const OrderItemsChecklistCard({super.key, required this.order});

  final RiderOrderModel order;

  @override
  Widget build(BuildContext context) {
    final items = order.order.items;
    final countLabel = items.isNotEmpty ? '${items.length} items' : '1 package';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.accentBg,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: const Icon(
                  LucideIcons.clipboardCheck,
                  size: 16,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order items',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Verify with Order #${order.order.orderNumber}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.rupees(
                      order.order.totalPaise / 100,
                    ),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(countLabel, style: AppTypography.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isNotEmpty)
            ...items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return _OrderItemRow(item: entry.value, isLast: isLast);
            })
          else
            const _FallbackPackageRow(),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item, required this.isLast});

  final OrderItemModel item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final foodColor = item.isVeg ? AppColors.success : AppColors.error;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FoodTypeDot(color: foodColor),
          const SizedBox(width: AppSpacing.sm),
          _QuantityBadge(quantity: item.quantity),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.instructions != null &&
                    item.instructions!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.instructions!.trim(),
                    style: AppTypography.caption.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackPackageRow extends StatelessWidget {
  const _FallbackPackageRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FoodTypeDot(color: AppColors.success),
        const SizedBox(width: AppSpacing.sm),
        const _QuantityBadge(quantity: 1),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sealed food package',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Confirm the order number with restaurant staff before pickup.',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FoodTypeDot extends StatelessWidget {
  const _FoodTypeDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${quantity}x',
        style: AppTypography.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
