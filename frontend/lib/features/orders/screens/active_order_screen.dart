import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/rider_order_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../providers/orders/active_order_provider.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/chips/status_chip.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/error_widget_custom.dart';
import '../widgets/cancel_order_sheet.dart';
import '../widgets/contact_actions.dart';
import '../widgets/delivery_otp_sheet.dart';
import '../widgets/pickup_qr_scanner_screen.dart';

enum _PrimaryAction { markArrived, scanQr, confirmPickup, startDelivery, completeDelivery, none }

_PrimaryAction _primaryActionFor(RiderOrderModel order) {
  switch (order.status) {
    case RiderOrderStatus.accepted:
      return _PrimaryAction.markArrived;
    case RiderOrderStatus.arrivedAtRestaurant:
      final qr = order.pickupQr;
      return (qr != null && qr.status == PickupQrStatus.used)
          ? _PrimaryAction.confirmPickup
          : _PrimaryAction.scanQr;
    case RiderOrderStatus.pickedUp:
      return _PrimaryAction.startDelivery;
    case RiderOrderStatus.outForDelivery:
      return _PrimaryAction.completeDelivery;
    default:
      return _PrimaryAction.none;
  }
}

/// The rider's current order, driven entirely by `RiderOrderModel.status`
/// (and, while ARRIVED_AT_RESTAURANT, the pickup QR's own status) — no
/// stage is hardcoded beyond mirroring the backend's own transition guards
/// exactly (`rider-order.transitions.ts`, `RiderOrdersService`).
class ActiveOrderScreen extends ConsumerStatefulWidget {
  const ActiveOrderScreen({super.key});

  @override
  ConsumerState<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends ConsumerState<ActiveOrderScreen>
    with WidgetsBindingObserver {
  bool _isProcessing = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      AppConstants.activeOrderPollInterval,
      (_) => ref.read(activeOrderProvider.notifier).refresh(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(activeOrderProvider.notifier).refresh();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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

  Future<void> _markArrived(String riderOrderId) =>
      _run(() => ref.read(activeOrderProvider.notifier).markArrived(riderOrderId));

  Future<void> _scanQr(String riderOrderId) => _run(() async {
        final token = await Get.to<String>(() => const PickupQrScannerScreen());
        if (token == null || token.isEmpty) return;
        await ref.read(activeOrderProvider.notifier).scanPickupQr(riderOrderId, token);
      });

  Future<void> _confirmPickup(String riderOrderId) =>
      _run(() => ref.read(activeOrderProvider.notifier).pickupSuccess(riderOrderId));

  Future<void> _startDelivery(String riderOrderId) =>
      _run(() => ref.read(activeOrderProvider.notifier).startDelivery(riderOrderId));

  Future<void> _completeDelivery(String riderOrderId, int attemptsRemaining) => _run(() async {
        final code =
            await DeliveryOtpSheet.show(context, attemptsRemaining: attemptsRemaining);
        if (code == null || code.length != 6) return;
        await ref.read(activeOrderProvider.notifier).completeDelivery(riderOrderId, code);
        if (!mounted) return;
        AppSnackBar.success(context, 'Delivery completed!');
        Get.back();
      });

  Future<void> _cancel(String riderOrderId) => _run(() async {
        final reason = await CancelOrderSheet.show(context);
        if (reason == null || reason.isEmpty) return;
        await ref.read(activeOrderProvider.notifier).cancel(riderOrderId, reason);
        if (!mounted) return;
        AppSnackBar.info(context, 'Order cancelled.');
        Get.back();
      });

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(activeOrderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Active order')),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 640,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: orderAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
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
                    const SizedBox(height: AppSpacing.lg),
                    _PrimaryActionButton(
                      order: order,
                      isProcessing: _isProcessing,
                      onMarkArrived: () => _markArrived(order.id),
                      onScanQr: () => _scanQr(order.id),
                      onConfirmPickup: () => _confirmPickup(order.id),
                      onStartDelivery: () => _startDelivery(order.id),
                      onCompleteDelivery: () => _completeDelivery(
                        order.id,
                        order.deliveryOtp?.attemptsRemaining ?? 5,
                      ),
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
  final VoidCallback onMarkArrived;
  final VoidCallback onScanQr;
  final VoidCallback onConfirmPickup;
  final VoidCallback onStartDelivery;
  final VoidCallback onCompleteDelivery;

  const _PrimaryActionButton({
    required this.order,
    required this.isProcessing,
    required this.onMarkArrived,
    required this.onScanQr,
    required this.onConfirmPickup,
    required this.onStartDelivery,
    required this.onCompleteDelivery,
  });

  @override
  Widget build(BuildContext context) {
    final action = _primaryActionFor(order);
    final (label, onPressed) = switch (action) {
      _PrimaryAction.markArrived => ('Mark arrived at restaurant', onMarkArrived),
      _PrimaryAction.scanQr => ('Scan pickup QR', onScanQr),
      _PrimaryAction.confirmPickup => ('Confirm pickup', onConfirmPickup),
      _PrimaryAction.startDelivery => ('Start delivery', onStartDelivery),
      _PrimaryAction.completeDelivery => ('Complete delivery', onCompleteDelivery),
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
