import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/order_model.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/chips/status_chip.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/accept_countdown_ring.dart';

class IncomingOrderScreen extends StatefulWidget {
  final OrderModel order;
  final int seconds;

  const IncomingOrderScreen({
    super.key,
    required this.order,
    this.seconds = 30,
  });

  @override
  State<IncomingOrderScreen> createState() => _IncomingOrderScreenState();
}

class _IncomingOrderScreenState extends State<IncomingOrderScreen> {
  bool _closed = false;

  void _close(bool accepted) {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop(accepted);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(false);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 520,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                AcceptCountdownRing(
                  seconds: widget.seconds,
                  onExpired: () => _close(false),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('New Order', style: AppTypography.h1),
                    const SizedBox(width: AppSpacing.sm),
                    StatusChip(
                      label: 'New',
                      color: AppColors.warning,
                      background: AppColors.warningBg,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _EarningBlock(amount: order.amount),
                        const SizedBox(height: AppSpacing.md),
                        _RouteBlock(order: order),
                        const SizedBox(height: AppSpacing.md),
                        _MetaRow(order: order),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryCtaButton(
                  label: 'Accept Order',
                  trailingIcon: LucideIcons.chevronsRight,
                  onPressed: () => _close(true),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: () => _close(false),
                  child: Text('Reject',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.error)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EarningBlock extends StatelessWidget {
  final double amount;
  const _EarningBlock({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        children: [
          Text('You earn', style: AppTypography.caption),
          Text(CurrencyFormatter.rupeesPrecise(amount),
              style: AppTypography.display.copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}

class _RouteBlock extends StatelessWidget {
  final OrderModel order;
  const _RouteBlock({required this.order});

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
        children: [
          _RouteRow(
            icon: LucideIcons.store,
            color: AppColors.secondary,
            title: order.restaurantName,
            subtitle: order.restaurantArea,
            trailing: '${order.pickupDistanceKm} km',
          ),
          const Padding(
            padding: EdgeInsets.only(left: 9),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 22,
                width: 2,
                child: ColoredBox(color: AppColors.border),
              ),
            ),
          ),
          _RouteRow(
            icon: LucideIcons.mapPin,
            color: AppColors.primary,
            title: order.dropAddress,
            subtitle: 'Trip · ${order.distanceKm} km · ${order.etaMinutes} mins',
            trailing: null,
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? trailing;

  const _RouteRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium),
              Text(subtitle, style: AppTypography.caption),
            ],
          ),
        ),
        if (trailing != null)
          Text(trailing!,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final OrderModel order;
  const _MetaRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Chip(
            icon: LucideIcons.shoppingBag,
            label: '${order.itemCount} items',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: _Chip(
            icon: LucideIcons.banknote,
            label: 'Prepaid',
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
