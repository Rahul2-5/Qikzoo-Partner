import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/order_history_page_model.dart';
import '../../../models/orders/rider_order_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../providers/location/rider_location_provider.dart';
import '../../../providers/location/rider_location_state.dart';
import '../../../providers/orders/active_order_provider.dart';
import '../../../providers/orders/order_history_provider.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/chips/status_chip.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/error_widget_custom.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
import '../widgets/cancel_order_sheet.dart';
import '../widgets/contactless_proof_sheet.dart';
import '../widgets/contact_actions.dart';
import '../widgets/delivery_handoff_card.dart';
import '../widgets/no_response_sheet.dart';
import '../widgets/quick_message_sheet.dart';

/// Client-side-only UX threshold for the "Mark delivered" button/copy — the
/// backend enforces its own real 150m default radius independently via a
/// server-side haversine check against `Rider.lastLat/lastLng`; this constant
/// never needs to match it exactly, it only has to give the rider an honest
/// sense of "close enough to try" before they tap.
const double _deliveryProximityThresholdMeters = 150;

/// The rider's live distance to the delivery coordinates, computed from
/// whatever position [RiderLocationController] currently holds — purely for
/// UX (disabling the button, showing "X away"). Tapping "Mark delivered"
/// always calls the real endpoint regardless of this estimate; the backend
/// re-checks GPS proximity itself and is the only authority that matters.
class _DeliveryProximity {
  final double? distanceMeters;
  final bool waitingForGps;

  const _DeliveryProximity({required this.distanceMeters, required this.waitingForGps});

  bool get isNear =>
      !waitingForGps &&
      distanceMeters != null &&
      distanceMeters! <= _deliveryProximityThresholdMeters;
}

_DeliveryProximity _computeDeliveryProximity(
  RiderLocationTrackingState locationState,
  RiderOrderModel order,
) {
  final riderLat = locationState.lastLat;
  final riderLng = locationState.lastLng;
  final deliveryLat = order.order.deliveryLat;
  final deliveryLng = order.order.deliveryLng;
  if (riderLat == null || riderLng == null || deliveryLat == null || deliveryLng == null) {
    return const _DeliveryProximity(distanceMeters: null, waitingForGps: true);
  }
  return _DeliveryProximity(
    distanceMeters: Geolocator.distanceBetween(riderLat, riderLng, deliveryLat, deliveryLng),
    waitingForGps: false,
  );
}

/// Formats a live-tracked distance as `"350 m away"` (< 1km) or
/// `"1.2 km away"` (>= 1km) — reusable anywhere this screen needs to show
/// "how far is the rider" from a point.
String formatDistanceAway(double meters) {
  if (meters < 1000) return '${meters.round()} m away';
  return '${(meters / 1000).toStringAsFixed(1)} km away';
}

enum _PrimaryAction { markArrived, startDelivery, completeDelivery, none }

_PrimaryAction _primaryActionFor(RiderOrderModel order) {
  switch (order.status) {
    case RiderOrderStatus.accepted:
      return _PrimaryAction.markArrived;
    case RiderOrderStatus.pickedUp:
      return _PrimaryAction.startDelivery;
    case RiderOrderStatus.outForDelivery:
      return _PrimaryAction.completeDelivery;
    default:
      // Includes ARRIVED_AT_RESTAURANT: the rider has nothing to tap while
      // waiting — see _PickupOtpWaitingPanel below. They never enter,
      // submit, or generate the pickup OTP; only restaurant staff do that
      // on their own dashboard, which flips the RiderOrder straight to
      // PICKED_UP for this screen to pick up via its existing polling.
      return _PrimaryAction.none;
  }
}

/// The rider's current order, driven entirely by `RiderOrderModel.status` —
/// no stage is hardcoded beyond mirroring the backend's own transition
/// guards exactly (`rider-order.transitions.ts`, `RiderOrdersService`).
class ActiveOrderScreen extends ConsumerStatefulWidget {
  const ActiveOrderScreen({super.key});

  @override
  ConsumerState<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends ConsumerState<ActiveOrderScreen> {
  bool _isProcessing = false;

  // activeOrderProvider is kept fresh by riderPollingControllerProvider's
  // single, app-lifetime timer (see its doc comment) regardless of which
  // tab/screen is on screen — this screen no longer needs its own
  // poll timer or app-lifecycle observer duplicating that work.

  Future<void> _run(Future<void> Function() action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await ref.read(authSessionProvider.notifier).logout();
        if (!mounted) return;
        Get.offAllNamed(AppRoutes.welcome);
        return;
      }
      AppSnackBar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _markArrived(String riderOrderId) =>
      _run(() => ref.read(activeOrderProvider.notifier).markArrived(riderOrderId));

  Future<void> _startDelivery(String riderOrderId) =>
      _run(() => ref.read(activeOrderProvider.notifier).startDelivery(riderOrderId));

  Future<void> _completeDelivery(String riderOrderId) => _run(() async {
        // No local "are we close enough" short-circuit here — the backend
        // is the sole authority on GPS proximity (it re-checks
        // Rider.lastLat/lastLng itself) and _run already surfaces its
        // rejection (stale GPS / too far / wrong state) via the same
        // snackbar path every other action on this screen uses.
        await ref.read(activeOrderProvider.notifier).completeDelivery(riderOrderId);
        // The backend flips the rider back to AVAILABLE on delivery
        // completion — the Dashboard Home screen stays mounted underneath
        // (bottom-tab scaffold) watching dashboardStatsProvider, which has
        // no periodic poll of its own, so without this it would keep
        // showing "Busy" until some unrelated trigger refreshed it.
        unawaited(ref.read(dashboardStatsProvider.notifier).refresh());
        // This order just moved into the Completed history filter — drop
        // both caches so the Orders tab shows it there (and no longer under
        // Ongoing) without needing a manual pull-to-refresh.
        _invalidateOrderHistory();
        if (!mounted) return;
        AppSnackBar.success(context, 'Delivery completed!');
        Get.back();
      });

  Future<void> _cancel(String riderOrderId) => _run(() async {
        final reason = await CancelOrderSheet.show(context);
        if (reason == null || reason.isEmpty) return;
        await ref.read(activeOrderProvider.notifier).cancel(riderOrderId, reason);
        // See the completeDelivery flow above — same reasoning.
        unawaited(ref.read(dashboardStatsProvider.notifier).refresh());
        _invalidateOrderHistory();
        if (!mounted) return;
        AppSnackBar.info(context, 'Order cancelled.');
        Get.back();
      });

  void _invalidateOrderHistory() {
    for (final filter in OrderHistoryFilter.values) {
      ref.invalidate(orderHistoryProvider(filter));
    }
  }

  Future<void> _showQuickMessage() async {
    final message = await QuickMessageSheet.show(context);
    if (!mounted || message == null) return;
    AppSnackBar.success(context, 'Message ready: $message');
  }

  Future<void> _showNoResponseFlow() async {
    final outcome = await NoResponseSheet.show(context);
    if (!mounted || outcome == null) return;
    if (outcome == NoResponseOutcome.contactSupport) {
      AppSnackBar.info(context, 'Support request ready for this delivery.');
      return;
    }
    final proofCaptured = await ContactlessProofSheet.show(context);
    if (mounted && proofCaptured == true) {
      AppSnackBar.success(context, 'Drop-off proof captured.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(activeOrderProvider);
    final locationState = ref.watch(riderLocationControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Active order')),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 640,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: orderAsync.when(
            loading: () => const PageLoadingShimmer(
              padding: EdgeInsets.zero,
              itemCount: 3,
            ),
            error: (error, _) => ErrorWidgetCustom(
              message: error is ApiException
                  ? error.message
                  : 'Could not load this order.',
              onRetry: () => ref.read(activeOrderProvider.notifier).refresh(),
            ),
            data: (order) {
              if (order == null) {
                return const EmptyState(
                  icon: LucideIcons.packageCheck,
                  message: 'No active order right now.',
                );
              }
              final deliveryProximity = _computeDeliveryProximity(locationState, order);
              return RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () => ref.read(activeOrderProvider.notifier).refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  children: [
                    _OrderHeader(order: order),
                    const SizedBox(height: AppSpacing.md),
                    ContactCard(
                      title: 'Restaurant',
                      name: order.restaurant.name,
                      address: order.restaurant.address,
                      landmark: order.restaurant.landmark,
                      phone: order.restaurant.phone,
                      latitude: order.restaurant.latitude,
                      longitude: order.restaurant.longitude,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ContactCard(
                      title: 'Customer',
                      name: order.order.customerName,
                      address: order.order.deliveryAddressLine ?? 'Address not available',
                      landmark: order.order.deliveryCity,
                      phone: order.order.customerPhone,
                      latitude: order.order.deliveryLat,
                      longitude: order.order.deliveryLng,
                    ),
                    if (order.status == RiderOrderStatus.outForDelivery) ...[
                      const SizedBox(height: AppSpacing.sm),
                      DeliveryHandoffCard(
                        buildingSummary:
                            order.order.deliveryAddressLine?.trim().isNotEmpty == true
                                ? order.order.deliveryAddressLine!
                                : (order.order.deliveryCity ?? 'Address shared with pickup'),
                        instruction: order.order.customerNote?.trim().isNotEmpty == true
                            ? order.order.customerNote!
                            : 'No delivery instructions provided.',
                        onCall: order.order.customerPhone == null
                            ? null
                            : () => launchPhoneCall(context, order.order.customerPhone!),
                        onQuickMessage: _showQuickMessage,
                        onNoResponse: _showNoResponseFlow,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DeliveryProximityPanel(proximity: deliveryProximity),
                    ],
                    if (order.status == RiderOrderStatus.arrivedAtRestaurant) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _PickupOtpWaitingPanel(order: order),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _PrimaryActionButton(
                      order: order,
                      isProcessing: _isProcessing,
                      deliveryReady: deliveryProximity.isNear,
                      onMarkArrived: () => _markArrived(order.id),
                      onStartDelivery: () => _startDelivery(order.id),
                      onCompleteDelivery: () => _completeDelivery(order.id),
                    ),
                    if (order.status.canCancel) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: _isProcessing ? null : () => _cancel(order.id),
                        child: Text(
                          'Cancel order',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  final RiderOrderModel order;

  const _OrderHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order #${order.order.orderNumber}', style: AppTypography.h2),
              if (order.distanceKm != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${order.distanceKm!.toStringAsFixed(1)} km'
                  '${order.etaMinutes != null ? ' · ${order.etaMinutes!.round()} min' : ''}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        StatusChip(
          label: order.status.label,
          color: AppColors.secondary,
          background: AppColors.secondary.withValues(alpha: 0.12),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final RiderOrderModel order;
  final bool isProcessing;

  /// Only meaningful for `_PrimaryAction.completeDelivery` — whether the
  /// rider's own live-tracked position is currently within
  /// [_deliveryProximityThresholdMeters] of the delivery coordinates. This
  /// is a UX gate only: the button stays disabled until then so the rider
  /// isn't invited to tap and immediately get rejected, but the backend is
  /// the real authority and re-checks GPS proximity itself once tapped.
  final bool deliveryReady;
  final VoidCallback onMarkArrived;
  final VoidCallback onStartDelivery;
  final VoidCallback onCompleteDelivery;

  const _PrimaryActionButton({
    required this.order,
    required this.isProcessing,
    required this.deliveryReady,
    required this.onMarkArrived,
    required this.onStartDelivery,
    required this.onCompleteDelivery,
  });

  @override
  Widget build(BuildContext context) {
    final action = _primaryActionFor(order);
    final (label, onPressed) = switch (action) {
      _PrimaryAction.markArrived => ('Mark arrived at restaurant', onMarkArrived),
      _PrimaryAction.startDelivery => ('Start delivery', onStartDelivery),
      _PrimaryAction.completeDelivery =>
        ('Mark delivered', deliveryReady ? onCompleteDelivery : null),
      _PrimaryAction.none => (null, null),
    };
    if (label == null) return const SizedBox.shrink();
    return PrimaryCtaButton(
      label: label,
      isLoading: isProcessing,
      onPressed: isProcessing ? null : onPressed,
    );
  }
}

/// Shown only while OUT_FOR_DELIVERY — the rider's own live distance/status
/// relative to the delivery coordinates, purely so they know whether tapping
/// "Mark delivered" is likely to succeed. Never an input: no OTP field, no
/// "share this code" text, nothing for the rider to type — the backend
/// alone decides via its own server-side GPS check.
class _DeliveryProximityPanel extends StatelessWidget {
  final _DeliveryProximity proximity;

  const _DeliveryProximityPanel({required this.proximity});

  @override
  Widget build(BuildContext context) {
    final ready = proximity.isNear;
    final statusLabel = proximity.waitingForGps
        ? 'Waiting for your location…'
        : ready
            ? "You're at the delivery location"
            : "You're not at the delivery location yet";
    final distanceLabel = (!proximity.waitingForGps && !ready && proximity.distanceMeters != null)
        ? formatDistanceAway(proximity.distanceMeters!)
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Icon(
            ready ? LucideIcons.mapPin : LucideIcons.mapPinOff,
            size: 20,
            color: ready ? AppColors.secondary : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusLabel, style: AppTypography.bodyMedium),
                if (distanceLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    distanceLabel,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
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

/// Read-only panel shown only while ARRIVED_AT_RESTAURANT — the rider is
/// just waiting here, there is no action to take. Displays the
/// restaurant-verified pickup OTP for the rider to read out to restaurant
/// staff (never an input — the rider never types this code, restaurant
/// staff confirm it on their own dashboard), plus a purely local elapsed-
/// time ticker. This panel disappears on its own once polling refreshes
/// `activeOrderProvider` and `order.status` moves past ARRIVED_AT_RESTAURANT,
/// since the whole ListView is already keyed off that status.
class _PickupOtpWaitingPanel extends StatelessWidget {
  final RiderOrderModel order;

  const _PickupOtpWaitingPanel({required this.order});

  @override
  Widget build(BuildContext context) {
    final code = order.order.pickupOtp?.code;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pickup OTP',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            code ?? '— — — —',
            style: AppTypography.h1.copyWith(letterSpacing: 6),
          ),
          const SizedBox(height: 4),
          Text(
            'Tell this OTP to the restaurant staff to collect the order.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          if (order.arrivedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            _WaitingTicker(arrivedAt: order.arrivedAt!),
          ],
        ],
      ),
    );
  }
}

/// A purely local UI clock — it never reads a provider or triggers a
/// network call, it only reformats the already-fetched `arrivedAt`
/// timestamp every second. `activeOrderProvider`'s own polling (unrelated
/// to this widget) is what keeps `arrivedAt`/`order.status` themselves
/// fresh.
class _WaitingTicker extends StatefulWidget {
  final DateTime arrivedAt;

  const _WaitingTicker({required this.arrivedAt});

  @override
  State<_WaitingTicker> createState() => _WaitingTickerState();
}

class _WaitingTickerState extends State<_WaitingTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.arrivedAt);
    final clamped = elapsed.isNegative ? Duration.zero : elapsed;
    final minutes = clamped.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = clamped.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Row(
      children: [
        const Icon(LucideIcons.clock3, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          'Waiting for restaurant · $minutes:$seconds',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
