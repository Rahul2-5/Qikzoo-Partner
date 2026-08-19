import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/order_history_page_model.dart';
import '../../../models/orders/rider_order_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../providers/location/rider_location_provider.dart';
import '../../../providers/location/rider_location_state.dart';
import '../../../providers/orders/active_order_provider.dart';
import '../../../providers/orders/order_history_provider.dart';
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
import '../widgets/order_items_checklist_card.dart';
import '../widgets/quick_message_sheet.dart';

/// Client-side-only UX threshold for the "Mark delivered" button/copy. The
/// backend enforces its own real 150m default radius independently via a
/// server-side haversine check against `Rider.lastLat/lastLng`.
const double _deliveryProximityThresholdMeters = 150;

class _DeliveryProximity {
  final double? distanceMeters;
  final bool waitingForGps;

  const _DeliveryProximity(
      {required this.distanceMeters, required this.waitingForGps});

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
  if (riderLat == null ||
      riderLng == null ||
      deliveryLat == null ||
      deliveryLng == null) {
    return const _DeliveryProximity(distanceMeters: null, waitingForGps: true);
  }
  return _DeliveryProximity(
    distanceMeters: Geolocator.distanceBetween(
        riderLat, riderLng, deliveryLat, deliveryLng),
    waitingForGps: false,
  );
}

String formatDistanceAway(double meters) {
  if (meters < 1000) return '${meters.round()} m away';
  return '${(meters / 1000).toStringAsFixed(1)} km away';
}

class ActiveOrderScreen extends ConsumerStatefulWidget {
  const ActiveOrderScreen({super.key});

  @override
  ConsumerState<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends ConsumerState<ActiveOrderScreen> {
  GoogleMapController? _mapController;
  bool _isProcessing = false;
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _mapController?.dispose();
    _otpController.dispose();
    super.dispose();
  }

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

  Future<void> _markArrived(String riderOrderId) => _run(
      () => ref.read(activeOrderProvider.notifier).markArrived(riderOrderId));

  Future<void> _verifyAndConfirmPickup(RiderOrderModel order) async {
    await _run(() async {
      try {
        await ref
            .read(activeOrderProvider.notifier)
            .pickupSuccess(order.id);
        if (!mounted) return;
        AppSnackBar.success(context, 'Order picked up successfully.');
      } on ApiException catch (e) {
        if (e.message.toLowerCase().contains('pickup qr') ||
            e.message.toLowerCase().contains('scan')) {
          // Try validating with the displayed OTP code
          try {
            await ref
                .read(activeOrderProvider.notifier)
                .scanPickupQr(order.id, order.displayPickupOtp);
            await ref
                .read(activeOrderProvider.notifier)
                .pickupSuccess(order.id);
            if (!mounted) return;
            AppSnackBar.success(context, 'Pickup verified & confirmed!');
            return;
          } catch (_) {
            if (!mounted) return;
            AppSnackBar.error(context,
                'Please ask restaurant staff to verify your OTP (${order.displayPickupOtp}) on their dashboard.');
            return;
          }
        }
        rethrow;
      }
    });
  }

  Future<void> _startDelivery(String riderOrderId) => _run(
      () => ref.read(activeOrderProvider.notifier).startDelivery(riderOrderId));

  Future<void> _refreshPickupStatus() =>
      _run(() => ref.read(activeOrderProvider.notifier).refresh());

  Future<void> _completeDelivery(String riderOrderId) async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      AppSnackBar.error(context, 'Enter the 6-digit delivery OTP.');
      return;
    }
    await _run(() async {
      await ref
          .read(activeOrderProvider.notifier)
          .completeDelivery(riderOrderId, code);
      unawaited(ref.read(dashboardStatsProvider.notifier).refresh());
      _invalidateOrderHistory();
      if (!mounted) return;
      AppSnackBar.success(context, 'Delivery completed!');
      Get.offAllNamed(AppRoutes.orders);
    });
  }

  Future<void> _cancel(String riderOrderId) => _run(() async {
        final reason = await CancelOrderSheet.show(context);
        if (reason == null || reason.isEmpty) return;
        await ref
            .read(activeOrderProvider.notifier)
            .cancel(riderOrderId, reason);
        unawaited(ref.read(dashboardStatsProvider.notifier).refresh());
        _invalidateOrderHistory();
        if (!mounted) return;
        AppSnackBar.info(context, 'Order cancelled.');
        Get.offAllNamed(AppRoutes.orders);
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

  void _updateCamera(
      RiderOrderModel order, RiderLocationTrackingState locationState) {
    if (_mapController == null) return;

    final riderLat = locationState.lastLat;
    final riderLng = locationState.lastLng;
    final restLat = order.restaurant.latitude;
    final restLng = order.restaurant.longitude;
    final destLat = order.order.deliveryLat;
    final destLng = order.order.deliveryLng;

    double? minLat, maxLat, minLng, maxLng;

    void updateBounds(double lat, double lng) {
      if (minLat == null || lat < minLat!) minLat = lat;
      if (maxLat == null || lat > maxLat!) maxLat = lat;
      if (minLng == null || lng < minLng!) minLng = lng;
      if (maxLng == null || lng > maxLng!) maxLng = lng;
    }

    final deliveryLeg = order.status == RiderOrderStatus.pickedUp ||
        order.status == RiderOrderStatus.outForDelivery;
    final currentLat = deliveryLeg && destLat != null ? destLat : restLat;
    final currentLng = deliveryLeg && destLng != null ? destLng : restLng;

    updateBounds(currentLat, currentLng);

    if (riderLat != null && riderLng != null) {
      updateBounds(riderLat, riderLng);
    } else {
      // Direct street-level camera focus on destination
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(currentLat, currentLng),
            zoom: 16.5,
          ),
        ),
      );
      return;
    }

    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      return;
    }

    final latSpan = (maxLat! - minLat!).abs();
    final lngSpan = (maxLng! - minLng!).abs();

    if (latSpan < 0.008 && lngSpan < 0.008) {
      // Nearby street-level view
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              (minLat! + maxLat!) / 2,
              (minLng! + maxLng!) / 2,
            ),
            zoom: 16.0,
          ),
        ),
      );
    } else {
      final latPadding = latSpan < 0.003 ? (0.003 - latSpan) / 2 : 0.0;
      final lngPadding = lngSpan < 0.003 ? (0.003 - lngSpan) / 2 : 0.0;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat! - latPadding, minLng! - lngPadding),
            northeast: LatLng(maxLat! + latPadding, maxLng! + lngPadding),
          ),
          48.0,
        ),
      );
    }
  }

  Set<Marker> _buildMarkers(
      RiderOrderModel order, RiderLocationTrackingState locationState) {
    final markers = <Marker>{};
    final deliveryLeg = order.status == RiderOrderStatus.pickedUp ||
        order.status == RiderOrderStatus.outForDelivery;

    if (deliveryLeg &&
        order.order.deliveryLat != null &&
        order.order.deliveryLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(order.order.deliveryLat!, order.order.deliveryLng!),
          infoWindow: InfoWindow(title: order.order.customerName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    } else {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position:
              LatLng(order.restaurant.latitude, order.restaurant.longitude),
          infoWindow: InfoWindow(title: order.restaurant.name ?? 'Restaurant'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    if (locationState.lastLat != null && locationState.lastLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: LatLng(locationState.lastLat!, locationState.lastLng!),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(
      RiderOrderModel order, RiderLocationTrackingState locationState) {
    final polylines = <Polyline>{};

    final riderLat = locationState.lastLat;
    final riderLng = locationState.lastLng;
    final restLat = order.restaurant.latitude;
    final restLng = order.restaurant.longitude;
    final destLat = order.order.deliveryLat;
    final destLng = order.order.deliveryLng;

    if (order.status == RiderOrderStatus.accepted ||
        order.status == RiderOrderStatus.arrivedAtRestaurant) {
      if (riderLat != null && riderLng != null) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('rider_to_restaurant'),
            points: [LatLng(riderLat, riderLng), LatLng(restLat, restLng)],
            color: AppColors.secondary.withValues(alpha: 0.82),
            width: 4,
            patterns: [PatternItem.dash(18), PatternItem.gap(10)],
          ),
        );
      }
    } else if (order.status == RiderOrderStatus.pickedUp ||
        order.status == RiderOrderStatus.outForDelivery) {
      final List<LatLng> points = [];
      if (riderLat != null && riderLng != null) {
        points.add(LatLng(riderLat, riderLng));
      } else {
        points.add(LatLng(restLat, restLng));
      }
      if (destLat != null && destLng != null) {
        points.add(LatLng(destLat, destLng));
      }
      if (points.length >= 2) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('rider_to_customer'),
            points: points,
            color: AppColors.secondary.withValues(alpha: 0.82),
            width: 4,
            patterns: [PatternItem.dash(18), PatternItem.gap(10)],
          ),
        );
      }
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(activeOrderProvider);
    final locationState = ref.watch(riderLocationControllerProvider);
    ref.listen<AsyncValue<RiderOrderModel?>>(activeOrderProvider,
        (previous, next) {
      if (previous?.valueOrNull == null || next.valueOrNull != null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Get.currentRoute == AppRoutes.activeOrder) {
          Get.offAllNamed(AppRoutes.orders);
        }
      });
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Get.offAllNamed(AppRoutes.orders);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 640,
            padding: EdgeInsets.zero,
            child: orderAsync.when(
              loading: () => const PageLoadingShimmer(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
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

                final deliveryProximity =
                    _computeDeliveryProximity(locationState, order);

                final deliveryLeg = order.status == RiderOrderStatus.pickedUp ||
                    order.status == RiderOrderStatus.outForDelivery;
                final mapCenterLat = deliveryLeg
                    ? order.order.deliveryLat ?? order.restaurant.latitude
                    : order.restaurant.latitude;
                final mapCenterLng = deliveryLeg
                    ? order.order.deliveryLng ?? order.restaurant.longitude
                    : order.restaurant.longitude;

                return RefreshIndicator(
                  color: AppColors.secondary,
                  onRefresh: () =>
                      ref.read(activeOrderProvider.notifier).refresh(),
                  child: Column(
                    children: [
                      // Actions stay outside the map so the route remains easy
                      // to inspect and accidental taps cannot advance an order.
                      if (!Get.testMode)
                        Container(
                          height: 200,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: Color(0xFFEEEEEE), width: 1),
                            ),
                          ),
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(mapCenterLat, mapCenterLng),
                                  zoom: 16.0,
                                ),
                                onMapCreated: (controller) {
                                  _mapController = controller;
                                  Future.delayed(
                                    const Duration(milliseconds: 500),
                                    () => _updateCamera(order, locationState),
                                  );
                                },
                                markers: _buildMarkers(order, locationState),
                                polylines: _buildPolylines(order, locationState),
                                myLocationEnabled: false,
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: false,
                                compassEnabled: false,
                                mapToolbarEnabled: false,
                                rotateGesturesEnabled: false,
                                tiltGesturesEnabled: false,
                                buildingsEnabled: false,
                              ),
                              // Floating Route Badge (Distance & ETA)
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.navigation2,
                                          size: 12, color: Colors.white),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${order.distanceKm?.toStringAsFixed(1) ?? '0.5'} km'
                                        '${order.etaMinutes != null ? ' • ${order.etaMinutes!.round()} min' : ''}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Floating Direct Google Maps Navigation Button
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      final destLat = deliveryLeg
                                          ? (order.order.deliveryLat ??
                                              order.restaurant.latitude)
                                          : order.restaurant.latitude;
                                      final destLng = deliveryLeg
                                          ? (order.order.deliveryLng ??
                                              order.restaurant.longitude)
                                          : order.restaurant.longitude;
                                      launchMaps(context, destLat, destLng);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.navigation,
                                              size: 13, color: Colors.white),
                                          SizedBox(width: 5),
                                          Text(
                                            'Navigate',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      _JourneyProgressHeader(
                        status: order.status,
                        arrivedAtCustomer: deliveryProximity.isNear,
                      ),

                      // Scrollable Order Details
                      Expanded(
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                          children: [
                            _OrderAtGlance(order: order),
                            const SizedBox(height: 12),
                            if (order.status == RiderOrderStatus.accepted ||
                                order.status ==
                                    RiderOrderStatus.arrivedAtRestaurant) ...[
                              ContactCard(
                                title: 'Pickup from',
                                isRestaurant: true,
                                name: order.restaurant.name,
                                address: order.restaurant.address,
                                landmark: order.restaurant.landmark,
                                phone: order.restaurant.phone,
                                latitude: order.restaurant.latitude,
                                longitude: order.restaurant.longitude,
                                distanceKm: order.distanceKm,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              OrderItemsChecklistCard(order: order),
                              if (order.status ==
                                  RiderOrderStatus.arrivedAtRestaurant) ...[
                                const SizedBox(height: AppSpacing.md),
                                _PickupVerificationCard(
                                  order: order,
                                  onRefresh: _refreshPickupStatus,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                            ],

                            if (order.status == RiderOrderStatus.pickedUp ||
                                order.status ==
                                    RiderOrderStatus.outForDelivery) ...[
                              ContactCard(
                                title: 'Deliver to',
                                isRestaurant: false,
                                name: order.order.customerName,
                                address: order.order.deliveryAddressLine ??
                                    'Address not available',
                                landmark: order.order.deliveryCity,
                                phone: order.order.customerPhone,
                                latitude: order.order.deliveryLat,
                                longitude: order.order.deliveryLng,
                                distanceKm: order.distanceKm,
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],

                            // Leg 2 extras (Delivery instructions & proximity panel)
                            if (order.status ==
                                RiderOrderStatus.outForDelivery) ...[
                              DeliveryHandoffCard(
                                buildingSummary:
                                    order.order.deliveryAddressLine ?? '',
                                instruction: order.order.customerNote ??
                                    'No delivery instructions.',
                                onCall: order.order.customerPhone == null
                                    ? null
                                    : () => launchPhoneCall(
                                        context, order.order.customerPhone!),
                                onQuickMessage: _showQuickMessage,
                                onNoResponse: _showNoResponseFlow,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _DeliveryProximityPanel(
                                proximity: deliveryProximity,
                              ),
                              if (deliveryProximity.isNear) ...[
                                const SizedBox(height: AppSpacing.md),
                                _DeliveryOtpCard(controller: _otpController),
                              ],
                              const SizedBox(height: AppSpacing.md),
                            ],

                            // Cancel action
                            if (order.status.canCancel)
                              Center(
                                child: TextButton(
                                  onPressed: _isProcessing
                                      ? null
                                      : () => _cancel(order.id),
                                  child: const Text(
                                    'Cancel order',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Single Primary Action Bar
                      if (order.status != RiderOrderStatus.delivered &&
                          order.status != RiderOrderStatus.cancelled)
                        SafeArea(
                          top: false,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              border: Border(
                                top: BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: _buildActionSection(
                              context,
                              order,
                              deliveryProximity,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    RiderOrderModel order,
    _DeliveryProximity proximity,
  ) {
    switch (order.status) {
      case RiderOrderStatus.accepted:
        return _StageActionButton(
          label: "I've Arrived",
          icon: LucideIcons.mapPin,
          isLoading: _isProcessing,
          backgroundColor: AppColors.primary,
          onPressed: _isProcessing ? null : () => _markArrived(order.id),
        );

      case RiderOrderStatus.arrivedAtRestaurant:
        return _StageActionButton(
          label: 'Picked Up',
          icon: LucideIcons.packageCheck,
          isLoading: _isProcessing,
          backgroundColor: AppColors.success,
          onPressed:
              _isProcessing ? null : () => _verifyAndConfirmPickup(order),
        );

      case RiderOrderStatus.pickedUp:
        return _StageActionButton(
          label: 'Start Delivery',
          icon: LucideIcons.bike,
          isLoading: _isProcessing,
          backgroundColor: AppColors.primary,
          onPressed: _isProcessing ? null : () => _startDelivery(order.id),
        );

      case RiderOrderStatus.outForDelivery:
        return _StageActionButton(
          label: 'Delivered',
          icon: LucideIcons.checkCircle2,
          isLoading: _isProcessing,
          backgroundColor: AppColors.success,
          onPressed: _isProcessing ? null : () => _completeDelivery(order.id),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _JourneyProgressHeader extends StatelessWidget {
  const _JourneyProgressHeader({
    required this.status,
    required this.arrivedAtCustomer,
  });

  final RiderOrderStatus status;
  final bool arrivedAtCustomer;

  @override
  Widget build(BuildContext context) {
    final snapshot = _journeySnapshot(status, arrivedAtCustomer);
    const stageCount = 8;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(snapshot.icon, size: 17, color: snapshot.color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  snapshot.label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Step ${snapshot.index + 1} of $stageCount',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: List.generate(stageCount, (index) {
              final complete = index <= snapshot.index;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(
                    right: index == stageCount - 1 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: complete
                        ? snapshot.color
                        : AppColors.border.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          if (snapshot.nextLabel != null) ...[
            const SizedBox(height: 7),
            Text(
              'Next: ${snapshot.nextLabel}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JourneySnapshot {
  const _JourneySnapshot({
    required this.index,
    required this.label,
    required this.nextLabel,
    required this.icon,
    required this.color,
  });

  final int index;
  final String label;
  final String? nextLabel;
  final IconData icon;
  final Color color;
}

_JourneySnapshot _journeySnapshot(
  RiderOrderStatus status,
  bool arrivedAtCustomer,
) {
  return switch (status) {
    RiderOrderStatus.assigned => const _JourneySnapshot(
        index: 0,
        label: 'Order received',
        nextLabel: 'Accept order',
        icon: LucideIcons.bellRing,
        color: AppColors.warning,
      ),
    RiderOrderStatus.accepted => const _JourneySnapshot(
        index: 2,
        label: 'Navigate to pickup',
        nextLabel: "Tap I've arrived at the restaurant",
        icon: LucideIcons.navigation,
        color: AppColors.primary,
      ),
    RiderOrderStatus.arrivedAtRestaurant => const _JourneySnapshot(
        index: 3,
        label: 'Arrived at restaurant',
        nextLabel: 'Verify pickup and confirm Picked up',
        icon: LucideIcons.store,
        color: AppColors.success,
      ),
    RiderOrderStatus.pickedUp => const _JourneySnapshot(
        index: 4,
        label: 'Pickup confirmed',
        nextLabel: 'Start delivery to the customer',
        icon: LucideIcons.packageCheck,
        color: AppColors.success,
      ),
    RiderOrderStatus.outForDelivery when arrivedAtCustomer =>
      const _JourneySnapshot(
        index: 6,
        label: 'Arrived at customer',
        nextLabel: 'Verify OTP and mark delivered',
        icon: LucideIcons.mapPin,
        color: AppColors.success,
      ),
    RiderOrderStatus.outForDelivery => const _JourneySnapshot(
        index: 5,
        label: 'On the way',
        nextLabel: 'Navigate to the customer',
        icon: LucideIcons.bike,
        color: AppColors.primary,
      ),
    RiderOrderStatus.delivered => const _JourneySnapshot(
        index: 7,
        label: 'Delivered',
        nextLabel: null,
        icon: LucideIcons.checkCircle2,
        color: AppColors.success,
      ),
    RiderOrderStatus.cancelled ||
    RiderOrderStatus.unknown =>
      const _JourneySnapshot(
        index: 0,
        label: 'Order update required',
        nextLabel: 'Refresh order status',
        icon: LucideIcons.alertCircle,
        color: AppColors.error,
      ),
  };
}

class _StageActionButton extends StatelessWidget {
  const _StageActionButton({
    required this.label,
    required this.onPressed,
    required this.icon,
    this.isLoading = false,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool isLoading;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: bg,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textDisabled,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 19, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OrderAtGlance extends StatelessWidget {
  const _OrderAtGlance({required this.order});

  final RiderOrderModel order;

  @override
  Widget build(BuildContext context) {
    final orderNum = order.order.orderNumber.trim().isNotEmpty
        ? order.order.orderNumber.trim()
        : order.id;
    final earningsText = CurrencyFormatter.rupees(order.earningsPaise / 100);
    final distanceText = order.distanceKm != null
        ? '${order.distanceKm!.toStringAsFixed(1)} km'
        : '-- km';
    final etaText = order.etaMinutes != null
        ? '${order.etaMinutes!.round()} min'
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OrderGlanceMetric(
              label: 'Order ID',
              value: '#$orderNum',
            ),
          ),
          const _GlanceDivider(),
          Expanded(
            child: _OrderGlanceMetric(
              label: 'Trip Distance',
              value: etaText != null ? '$distanceText • $etaText' : distanceText,
            ),
          ),
          const _GlanceDivider(),
          Expanded(
            child: _OrderGlanceMetric(
              label: 'Your Earning',
              value: earningsText,
              valueColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderGlanceMetric extends StatelessWidget {
  const _OrderGlanceMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

class _GlanceDivider extends StatelessWidget {
  const _GlanceDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 9),
        color: AppColors.border,
      );
}

class _DeliveryOtpCard extends StatelessWidget {
  const _DeliveryOtpCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Delivery verification',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask the customer for the 6-digit delivery OTP.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: AppTypography.numericMd.copyWith(letterSpacing: 4),
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryProximityPanel extends StatelessWidget {
  final _DeliveryProximity proximity;

  const _DeliveryProximityPanel({required this.proximity});

  @override
  Widget build(BuildContext context) {
    final ready = proximity.isNear;
    final statusLabel = proximity.waitingForGps
        ? 'Waiting for your location...'
        : ready
            ? "You're at the delivery location"
            : "You're not at the delivery location yet";
    final distanceLabel =
        (!proximity.waitingForGps && !ready && proximity.distanceMeters != null)
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
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
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

class _PickupVerificationCard extends StatelessWidget {
  const _PickupVerificationCard({
    required this.order,
    this.onRefresh,
  });

  final RiderOrderModel order;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final otpCode = order.displayPickupOtp;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.shieldCheck,
                size: 18,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pickup Verification OTP',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  tooltip: 'Refresh Status',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRefresh,
                  icon: const Icon(LucideIcons.refreshCw,
                      size: 15, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Show this OTP to restaurant staff. They will enter it on their terminal to verify and hand over the order.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          // Individual OTP Digit Boxes
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < otpCode.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.45),
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      otpCode[i],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'PlusJakartaSans',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Copy Button
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Clipboard.setData(ClipboardData(text: otpCode));
                AppSnackBar.success(context, 'Pickup OTP ($otpCode) copied.');
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.copy,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Copy OTP',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (order.arrivedAt != null) ...[
            const SizedBox(height: 10),
            _WaitingTicker(arrivedAt: order.arrivedAt!),
          ],
        ],
      ),
    );
  }
}

class _OtpExpiryTicker extends StatefulWidget {
  const _OtpExpiryTicker({required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<_OtpExpiryTicker> createState() => _OtpExpiryTickerState();
}

class _OtpExpiryTickerState extends State<_OtpExpiryTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.expiresAt.difference(DateTime.now());
    final seconds = remaining.isNegative ? 0 : remaining.inSeconds;
    final minutesLabel = (seconds ~/ 60).toString().padLeft(2, '0');
    final secondsLabel = (seconds % 60).toString().padLeft(2, '0');
    return Row(
      children: [
        const Icon(LucideIcons.timer, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          seconds == 0
              ? 'OTP expired - refresh to get the latest status'
              : 'OTP valid for $minutesLabel:$secondsLabel',
          style: AppTypography.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

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
        const Icon(LucideIcons.clock3,
            size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          'Waiting for restaurant - $minutes:$seconds',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
