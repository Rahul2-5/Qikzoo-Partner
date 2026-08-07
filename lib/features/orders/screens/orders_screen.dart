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
import '../../../core/utils/currency_formatter.dart';
import '../../../models/dashboard/dashboard_stats_model.dart';
import '../../../models/orders/order_history_page_model.dart';
import '../../../models/orders/rider_order_model.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../providers/orders/active_order_provider.dart';
import '../../../providers/orders/order_history_provider.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';
import '../data/order_preview_data.dart';
import '../widgets/order_history_list.dart';

/// The landing view for a rider's current and historical orders.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  OrderHistoryFilter _filter = OrderHistoryFilter.active;
  final Set<String> _rejectedOfferIds = {};
  RiderOrderModel? _acceptedFrontendOffer;
  String? _selectedFrontendOfferId;

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
    final showOrderPreviews = ref.watch(showOrderPreviewProvider);
    final frontendOffers = orderPreviewsFor(OrderHistoryFilter.active)
        .where((order) => !_rejectedOfferIds.contains(order.id))
        .toList(growable: false);
    // A rider can hold only one active assignment. Keep the active tab and
    // its count tied to that single source of truth rather than to paginated
    // history, which can contain stale active rows while an order progresses.
    final activeOrder = activeOrderAsync.valueOrNull;
    final orderCount = _filter == OrderHistoryFilter.active
        ? (activeOrder != null || _acceptedFrontendOffer != null
            ? 1
            : frontendOffers.length)
        : history?.items.isEmpty == true && showOrderPreviews
            ? orderPreviewsFor(_filter).length
            : history?.total;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTabScaffold(
        currentIndex: 2,
        child: ResponsiveFrame(
          maxWidth: 640,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrdersHeader(
                orderCount: orderCount,
                availability: availability,
              ),
              const SizedBox(height: AppSpacing.md),
              activeOrderAsync.maybeWhen(
                data: (order) => order == null
                    ? const SizedBox.shrink()
                    : _ActiveOrderBanner(
                        onTap: () => Get.toNamed(AppRoutes.activeOrder),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
              if (activeOrder == null && _acceptedFrontendOffer != null)
                _FrontendAcceptedBanner(
                  order: _acceptedFrontendOffer!,
                  onTap: () => _openOrder(_acceptedFrontendOffer!.id),
                ),
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
                        OrderHistoryFilter.active => 'Ongoing',
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
                child: _filter == OrderHistoryFilter.active
                    ? activeOrder != null || _acceptedFrontendOffer != null
                        ? const SizedBox.shrink()
                        : _OrderOfferQueue(
                            offers: frontendOffers,
                            selectedOfferId: _selectedFrontendOfferId,
                            onSelect: (offer) => setState(
                              () => _selectedFrontendOfferId = offer.id,
                            ),
                            onAccept: (offer) => setState(
                              () => _acceptedFrontendOffer = offer,
                            ),
                            onReject: (offer) => setState(() {
                              _rejectedOfferIds.add(offer.id);
                              if (_selectedFrontendOfferId == offer.id) {
                                _selectedFrontendOfferId = null;
                              }
                            }),
                          )
                    : OrderHistoryList(filter: _filter, onOpen: _openOrder),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frontend-only offer selection UI. Its sample data is intentionally kept
/// local until the dispatch API exposes a list of offer details and payouts.
class _OrderOfferQueue extends StatelessWidget {
  const _OrderOfferQueue({
    required this.offers,
    required this.selectedOfferId,
    required this.onSelect,
    required this.onAccept,
    required this.onReject,
  });

  final List<RiderOrderModel> offers;
  final String? selectedOfferId;
  final ValueChanged<RiderOrderModel> onSelect;
  final ValueChanged<RiderOrderModel> onAccept;
  final ValueChanged<RiderOrderModel> onReject;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return Center(
        child: Text(
          'No delivery offers right now.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final priceListWidth = constraints.maxWidth >= 560 ? 114.0 : 88.0;
        final selectedId = offers.any((offer) => offer.id == selectedOfferId)
            ? selectedOfferId
            : offers.first.id;
        return Row(
          children: [
            SizedBox(
              width: priceListWidth,
              child: _OfferPriceList(
                offers: offers,
                selectedOfferId: selectedId,
                onSelect: onSelect,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                itemCount: offers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) => _OrderOfferCard(
                  order: offers[index],
                  selected: offers[index].id == selectedId,
                  onTap: () => onSelect(offers[index]),
                  onAccept: () => onAccept(offers[index]),
                  onReject: () => onReject(offers[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OfferPriceList extends StatelessWidget {
  const _OfferPriceList({
    required this.offers,
    required this.selectedOfferId,
    required this.onSelect,
  });

  final List<RiderOrderModel> offers;
  final String? selectedOfferId;
  final ValueChanged<RiderOrderModel> onSelect;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted.withValues(alpha: .6),
          border: Border(
            right: BorderSide(color: AppColors.border.withValues(alpha: .8)),
          ),
        ),
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          itemCount: offers.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: AppColors.border.withValues(alpha: .8)),
          itemBuilder: (context, index) {
            final offer = offers[index];
            final selected = offer.id == selectedOfferId;
            return Semantics(
              button: true,
              selected: selected,
              label:
                  '${CurrencyFormatter.rupees(offer.earningsPaise / 100)} offer${selected ? ', selected' : ''}',
              child: Material(
                color: selected ? AppColors.successBg : AppColors.surface,
                child: InkWell(
                  onTap: () => onSelect(offer),
                  child: Container(
                    height: 92,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: selected
                          ? const Border(
                              left: BorderSide(
                                color: AppColors.success,
                                width: 6,
                              ),
                            )
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatter.rupees(offer.earningsPaise / 100),
                        style: AppTypography.numericMd.copyWith(
                          color: selected
                              ? AppColors.success
                              : AppColors.textPrimary,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _OrderOfferCard extends StatelessWidget {
  const _OrderOfferCard({
    required this.order,
    required this.selected,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
  });

  final RiderOrderModel order;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final pickup = order.restaurant.address?.trim().isNotEmpty == true
        ? order.restaurant.address!
        : 'Pickup location shared after accepting';
    final drop = order.order.deliveryAddressLine?.trim().isNotEmpty == true
        ? order.order.deliveryAddressLine!
        : 'Drop location shared after accepting';
    final customer = order.order.customerName.trim().isEmpty
        ? 'Delivery customer'
        : order.order.customerName;

    return Semantics(
      container: true,
      label:
          'Delivery offer from ${order.restaurant.name ?? 'restaurant'}, earning ${CurrencyFormatter.rupees(order.earningsPaise / 100)}',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card + 4),
            border: Border.all(
              color: selected ? AppColors.success : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: AppShadows.card,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card + 4),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OfferStop(
                    icon: Icons.restaurant_rounded,
                    title: order.restaurant.name ?? 'Restaurant order',
                    distance:
                        '${(order.distanceKm ?? 0).toStringAsFixed(1)} km',
                    address: pickup,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Container(
                      width: 2,
                      height: 22,
                      color: AppColors.border,
                    ),
                  ),
                  _OfferStop(
                    icon: Icons.person_rounded,
                    title: customer,
                    distance: 'Drop-off',
                    address: drop,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: .2),
                            ),
                            backgroundColor:
                                AppColors.error.withValues(alpha: .08),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: onAccept,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: AppColors.success,
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferStop extends StatelessWidget {
  const _OfferStop({
    required this.icon,
    required this.title,
    required this.distance,
    required this.address,
  });

  final IconData icon;
  final String title;
  final String distance;
  final String address;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 21, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 17),
                ),
                Text(
                  distance,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _FrontendAcceptedBanner extends StatelessWidget {
  const _FrontendAcceptedBanner({required this.order, required this.onTap});

  final RiderOrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Material(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Delivery accepted • ${order.restaurant.name ?? 'Order'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.orderCount,
    required this.availability,
  });

  final int? orderCount;
  final RiderAvailabilityStatus? availability;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE, d MMM').format(DateTime.now());
    final countLabel = orderCount == null
        ? null
        : '$orderCount ${orderCount == 1 ? 'order' : 'orders'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _AvailabilityPill(availability: availability),
              ),
              const IgnorePointer(child: _PartnerWordmark()),
              const Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeaderIcon(icon: LucideIcons.bell),
                    SizedBox(width: AppSpacing.xs),
                    _HeaderIcon(icon: LucideIcons.helpCircle),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Orders', style: AppTypography.display),
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
            const _HeaderIcon(icon: LucideIcons.search),
            const SizedBox(width: AppSpacing.sm),
            const _HeaderIcon(icon: LucideIcons.slidersHorizontal),
          ],
        ),
      ],
    );
  }
}

class _PartnerWordmark extends StatelessWidget {
  const _PartnerWordmark();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Qikzoo',
            style: AppTypography.h2.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          Text(
            'PARTNER',
            style: AppTypography.caption.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: 8,
            ),
          ),
        ],
      );
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {},
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppShadows.control,
            ),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
        ),
      );
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.availability});

  final RiderAvailabilityStatus? availability;

  @override
  Widget build(BuildContext context) {
    final isOnline = availability?.isOnlineFacing ?? false;
    final label = availability == null
        ? 'Checking'
        : isOnline
            ? 'Online'
            : 'Offline';
    final color = isOnline ? AppColors.success : AppColors.textSecondary;

    return Semantics(
      label: 'Availability: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
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
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronDown, size: 16),
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
            padding: const EdgeInsets.symmetric(horizontal: 15),
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
