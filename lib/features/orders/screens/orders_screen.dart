import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/dashboard/dashboard_stats_model.dart';
import '../../../models/orders/order_history_page_model.dart';
import '../../../models/orders/rider_order_model.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../providers/orders/active_order_provider.dart';
import '../../../providers/orders/order_history_provider.dart';
import '../../../shared/utils/rider_status_tone_color.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';
import '../../../shared/widgets/navigation/partner_app_header.dart';
import '../widgets/order_history_list.dart';
import '../widgets/rider_order_list_tile.dart';

/// The landing view for a rider's current and historical orders.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  OrderHistoryFilter _filter = OrderHistoryFilter.active;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      }
    });
    if (_isSearching) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _searchFocusNode.requestFocus(),
      );
    }
  }

  Future<void> _openFilterSheet() async {
    var selected = _filter;
    final result = await showModalBottomSheet<OrderHistoryFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Filter orders', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choose which order status you want to view.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...OrderHistoryFilter.values.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Material(
                    color: selected == option
                        ? AppColors.primarySoft
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      onTap: () => setSheetState(() => selected = option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.label,
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                            Icon(
                              selected == option
                                  ? LucideIcons.checkCircle2
                                  : LucideIcons.circle,
                              color: selected == option
                                  ? AppColors.primary
                                  : AppColors.textDisabled,
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(selected),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                ),
                child: const Text('Apply filter'),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) setState(() => _filter = result);
  }

  void _openOrder(String riderOrderId) {
    Get.toNamed(AppRoutes.orderDetails, arguments: riderOrderId);
  }

  @override
  Widget build(BuildContext context) {
    final activeOrderAsync = ref.watch(activeOrderProvider);
    final historyAsync = ref.watch(orderHistoryProvider(_filter));
    final availability =
        ref.watch(dashboardStatsProvider).valueOrNull?.availabilityStatus;
    final history = historyAsync.valueOrNull;
    // A rider can hold only one active assignment. Keep the active tab and
    // its count tied to that single source of truth rather than to paginated
    // history, which can contain stale active rows while an order progresses.
    final activeOrder = activeOrderAsync.valueOrNull;
    final activeOrderMatches =
        activeOrder != null && _orderMatchesSearch(activeOrder, _searchQuery);
    final orderCount = _filter == OrderHistoryFilter.active
        ? (activeOrder != null ? 1 : 0)
        : history?.total;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTabScaffold(
        currentIndex: 2,
        child: ResponsiveFrame(
          // Keep dense order information readable on tablet and desktop
          // windows instead of stretching each card across the screen.
          maxWidth: 560,
          padding: const EdgeInsets.fromLTRB(
            12,
            AppSpacing.sm,
            12,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrdersHeader(
                orderCount: orderCount,
                availability: availability,
                isSearching: _isSearching,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                onSearchPressed: _toggleSearch,
                onSearchChanged: (value) => setState(
                  () => _searchQuery = value.trim().toLowerCase(),
                ),
                onFilterPressed: _openFilterSheet,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: OrderHistoryFilter.values.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final filter = OrderHistoryFilter.values[index];
                    return _OrderFilterTab(
                      label: switch (filter) {
                        OrderHistoryFilter.active => 'Active',
                        OrderHistoryFilter.completed => 'Completed',
                        OrderHistoryFilter.cancelled => 'Cancelled',
                      },
                      count: filter == _filter ? orderCount : null,
                      selected: _filter == filter,
                      onTap: () => setState(() => _filter = filter),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _filter == OrderHistoryFilter.active &&
                        activeOrderMatches
                    ? RefreshIndicator(
                        color: AppColors.secondary,
                        onRefresh: () =>
                            ref.read(activeOrderProvider.notifier).refresh(),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            _ActiveOrderBanner(
                              onTap: () => Get.toNamed(AppRoutes.activeOrder),
                            ),
                            RiderOrderListTile(
                              order: activeOrder,
                              onTap: () => Get.toNamed(AppRoutes.activeOrder),
                            ),
                          ],
                        ),
                      )
                    : _filter == OrderHistoryFilter.active &&
                            activeOrder != null &&
                            _searchQuery.isNotEmpty
                        ? EmptyState(
                            icon: LucideIcons.searchX,
                            title: 'No matching active order',
                            message:
                                'Try a different order number, customer, restaurant, or location.',
                            actionLabel: 'Clear search',
                            onAction: _toggleSearch,
                          )
                        : OrderHistoryList(
                            filter: _filter,
                            searchQuery: _searchQuery,
                            onOpen: _openOrder,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.orderCount,
    required this.availability,
    required this.isSearching,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchPressed,
    required this.onSearchChanged,
    required this.onFilterPressed,
  });

  final int? orderCount;
  final RiderAvailabilityStatus? availability;
  final bool isSearching;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onSearchPressed;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE, d MMM').format(DateTime.now());
    final countLabel = orderCount == null
        ? null
        : '$orderCount ${orderCount == 1 ? 'order' : 'orders'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Orders', style: AppTypography.h1),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(date,
                          style: AppTypography.body
                              .copyWith(color: AppColors.textSecondary)),
                      if (countLabel != null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 7),
                          child: Text('•',
                              style: TextStyle(color: AppColors.textDisabled)),
                        ),
                        Text(countLabel, style: AppTypography.caption),
                      ],
                      const SizedBox(width: 2),
                      const Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PartnerHeaderIconButton(
              icon: isSearching ? LucideIcons.x : LucideIcons.search,
              label: isSearching ? 'Close search' : 'Search orders',
              onPressed: onSearchPressed,
            ),
            const SizedBox(width: AppSpacing.sm),
            PartnerHeaderIconButton(
              icon: LucideIcons.slidersHorizontal,
              label: 'Filter orders',
              onPressed: onFilterPressed,
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: isSearching
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    onChanged: onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search order, customer, restaurant or area',
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      suffixIcon: searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                searchController.clear();
                                onSearchChanged('');
                              },
                              icon: const Icon(LucideIcons.x, size: 18),
                            ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.xs),
        _AvailabilityPill(availability: availability, compact: true),
      ],
    );
  }
}

bool _orderMatchesSearch(RiderOrderModel order, String query) {
  if (query.isEmpty) return true;
  final values = <String?>[
    order.id,
    order.orderId,
    order.order.orderNumber,
    order.order.customerName,
    order.restaurant.name,
    order.restaurant.address,
    order.order.deliveryAddressLine,
    order.order.deliveryCity,
    order.order.deliveryPincode,
  ];
  return values.any(
    (value) => value?.toLowerCase().contains(query) ?? false,
  );
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.availability, this.compact = false});

  final RiderAvailabilityStatus? availability;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Derived from the backend-authoritative RiderAvailabilityStatus via
    // its own statusTone/statusChipLabel — the same source the Dashboard's
    // shift badge reads from — rather than a locally re-derived
    // online/offline boolean, so BUSY can't be silently collapsed into
    // "Online" here independently of how the Dashboard renders it.
    final label = availability?.statusChipLabel ?? 'Checking';
    final color = availability == null
        ? AppColors.textSecondary
        : riderStatusToneColor(availability!.statusTone);

    return Semantics(
      label: 'Availability: $label',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 13,
          vertical: compact ? 6 : 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          boxShadow: AppShadows.control,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 7 : 9,
              height: compact ? 7 : 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: compact ? 6 : 8),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 14,
              ),
            ),
            SizedBox(width: compact ? 4 : 6),
            Icon(LucideIcons.chevronDown, size: compact ? 14 : 16),
          ],
        ),
      ),
    );
  }
}

class _OrderFilterTab extends StatelessWidget {
  const _OrderFilterTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: selected ? AppColors.secondary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primarySoft
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.caption.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class _ActiveOrderBanner extends StatelessWidget {
  const _ActiveOrderBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.ctaGradient),
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: AppShadows.cta,
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.navigation, color: Colors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'You have an order in progress',
                      style: AppTypography.bodyMedium
                          .copyWith(color: Colors.white),
                    ),
                  ),
                  const Icon(LucideIcons.arrowRight, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      );
}
