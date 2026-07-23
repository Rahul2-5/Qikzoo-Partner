import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/order_history_page_model.dart';
import '../../../providers/orders/active_order_provider.dart';
import '../../../shared/widgets/chips/filter_chip_custom.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/app_bottom_nav.dart';
import '../widgets/order_history_list.dart';

/// The Orders tab's landing screen: a persistent "Active order" banner
/// (if the rider has one — recovers it via `activeOrderProvider`, backed
/// by `GET /rider/orders/current`) above the paginated
/// Active/Completed/Cancelled history tabs.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  OrderHistoryFilter _filter = OrderHistoryFilter.active;

  void _openOrder(String riderOrderId) {
    Get.toNamed(AppRoutes.orderDetails, arguments: riderOrderId);
  }

  @override
  Widget build(BuildContext context) {
    final activeOrderAsync = ref.watch(activeOrderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 640,
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Orders', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.md),
              activeOrderAsync.maybeWhen(
                data: (order) => order == null
                    ? const SizedBox.shrink()
                    : _ActiveOrderBanner(
                        onTap: () => Get.toNamed(AppRoutes.activeOrder),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
              Row(
                children: [
                  for (final filter in OrderHistoryFilter.values) ...[
                    FilterChipCustom(
                      label: filter.label,
                      selected: _filter == filter,
                      onTap: () => setState(() => _filter = filter),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: OrderHistoryList(filter: _filter, onOpen: _openOrder),
              ),
              const AppBottomNav(currentIndex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveOrderBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _ActiveOrderBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.secondary,
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
            child: Row(
              children: [
                const Icon(LucideIcons.bike, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'You have an order in progress',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
