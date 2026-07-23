import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/rider_order_model.dart';

/// The RestaurantOrder's full status history — only ever populated on the
/// `GET /rider/orders/:id` response (see `RiderOrdersService`'s doc
/// comment on why `current`/`history` deliberately omit it).
class OrderStatusTimeline extends StatelessWidget {
  final List<OrderStatusHistoryEntry> entries;

  const OrderStatusTimeline({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final formatter = DateFormat('d MMM, h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: i == entries.length - 1
                            ? AppColors.success
                            : AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < entries.length - 1)
                      Container(width: 2, height: 28, color: AppColors.border),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entries[i].toStatus.label, style: AppTypography.bodyMedium),
                      Text(
                        formatter.format(entries[i].changedAt.toLocal()),
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      if (entries[i].reason != null) ...[
                        const SizedBox(height: 2),
                        Text(entries[i].reason!, style: AppTypography.caption),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
