import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/inputs/search_bar_custom.dart';

class OrdersHeader extends StatefulWidget {
  final bool searchOpen;
  final String query;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onOpenFilter;

  const OrdersHeader({
    super.key,
    required this.searchOpen,
    required this.query,
    required this.onToggleSearch,
    required this.onQueryChanged,
    required this.onOpenFilter,
  });

  @override
  State<OrdersHeader> createState() => _OrdersHeaderState();
}

class _OrdersHeaderState extends State<OrdersHeader> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QIKZOO',
                    style: AppTypography.h2.copyWith(color: AppColors.primary)),
                Text('Delivery Partner', style: AppTypography.caption),
              ],
            ),
            const Spacer(),
            const _OnlinePill(),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text('My Orders', style: AppTypography.h1),
            const Spacer(),
            _IconAction(
              icon: LucideIcons.search,
              tooltip: 'Search',
              onTap: widget.onToggleSearch,
            ),
            const SizedBox(width: AppSpacing.sm),
            _IconAction(
              icon: LucideIcons.slidersHorizontal,
              tooltip: 'Filter',
              onTap: widget.onOpenFilter,
            ),
          ],
        ),
        if (widget.searchOpen) ...[
          const SizedBox(height: AppSpacing.md),
          SearchBarCustom(
            controller: _controller,
            hint: 'Search by restaurant or order ID',
            onChanged: widget.onQueryChanged,
          ),
        ],
      ],
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        boxShadow: AppShadows.control,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Online', style: AppTypography.bodyMedium),
          const Icon(LucideIcons.chevronDown,
              size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}
