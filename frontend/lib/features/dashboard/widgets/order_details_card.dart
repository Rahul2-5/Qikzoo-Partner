import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/order_model.dart';

class OrderDetailsCard extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsCard({super.key, required this.order});

  void _copyId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: order.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order ID copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child:
                    const Icon(LucideIcons.store, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.restaurantName, style: AppTypography.bodyMedium),
                    Text(order.restaurantArea, style: AppTypography.caption),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.phone, size: 16),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.border),
          Row(
            children: [
              const Icon(LucideIcons.clipboard,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ID', style: AppTypography.caption),
                    Text(order.id, style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _copyId(context),
                icon: const Icon(LucideIcons.copy, size: 16),
                label: const Text('Copy'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.border),
          _ExpandableRow(
            icon: LucideIcons.shoppingBag,
            title: 'Order Items',
            preview: order.itemsSummary,
            detail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: order.items
                  .map((i) => Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text('${i.quantity} x ${i.name}',
                            style: AppTypography.body),
                      ))
                  .toList(),
            ),
          ),
          if (order.customerNote != null &&
              order.customerNote!.isNotEmpty) ...[
            const Divider(height: AppSpacing.lg, color: AppColors.border),
            _ExpandableRow(
              icon: LucideIcons.stickyNote,
              title: 'Note from customer',
              preview: order.customerNote!,
              detail: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(order.customerNote!, style: AppTypography.body),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpandableRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final String preview;
  final Widget detail;

  const _ExpandableRow({
    required this.icon,
    required this.title,
    required this.preview,
    required this.detail,
  });

  @override
  State<_ExpandableRow> createState() => _ExpandableRowState();
}

class _ExpandableRowState extends State<_ExpandableRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTypography.caption),
                    Text(widget.preview,
                        maxLines: _open ? 10 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              Icon(_open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                _open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Align(
                alignment: Alignment.centerLeft, child: widget.detail),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
