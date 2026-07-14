import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/order_list_entry.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/chips/filter_chip_custom.dart';

class OrdersFilterResult {
  final OrdersSort sort;
  final OrdersDateFilter dateFilter;

  const OrdersFilterResult({required this.sort, required this.dateFilter});
}

class OrderFilterSheet extends StatefulWidget {
  final OrdersSort sort;
  final OrdersDateFilter dateFilter;

  const OrderFilterSheet({
    super.key,
    required this.sort,
    required this.dateFilter,
  });

  static Future<OrdersFilterResult?> show(
    BuildContext context, {
    required OrdersSort sort,
    required OrdersDateFilter dateFilter,
  }) {
    return showModalBottomSheet<OrdersFilterResult>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (_) => OrderFilterSheet(sort: sort, dateFilter: dateFilter),
    );
  }

  @override
  State<OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<OrderFilterSheet> {
  late OrdersSort _sort = widget.sort;
  late OrdersDateFilter _dateFilter = widget.dateFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Sort & Filter', style: AppTypography.h2)),
              TextButton(
                onPressed: () => setState(() {
                  _sort = OrdersSort.newest;
                  _dateFilter = OrdersDateFilter.all;
                }),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Sort by', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final s in OrdersSort.values)
                FilterChipCustom(
                  label: s.label,
                  selected: s == _sort,
                  onTap: () => setState(() => _sort = s),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Date', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final d in OrdersDateFilter.values)
                FilterChipCustom(
                  label: d.label,
                  selected: d == _dateFilter,
                  onTap: () => setState(() => _dateFilter = d),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryCtaButton(
            label: 'Apply',
            onPressed: () => Navigator.of(context).pop(
              OrdersFilterResult(sort: _sort, dateFilter: _dateFilter),
            ),
          ),
        ],
      ),
    );
  }
}
