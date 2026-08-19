import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/dispatch_offer_model.dart';
import '../../../models/orders/order_history_page_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../providers/orders/active_order_provider.dart';
import '../../../providers/orders/dispatch_offer_provider.dart';
import '../../../providers/orders/order_history_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/countdown_timer.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/error_widget_custom.dart';

class IncomingOfferScreen extends ConsumerStatefulWidget {
  const IncomingOfferScreen({super.key});

  @override
  ConsumerState<IncomingOfferScreen> createState() =>
      _IncomingOfferScreenState();
}

class _IncomingOfferScreenState extends ConsumerState<IncomingOfferScreen> {
  bool _isProcessing = false;
  bool _expiryHandled = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(
      AppConstants.dispatchOfferPollInterval,
      (_) => ref.read(dispatchOfferProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _accept(DispatchOfferModel offer) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final riderOrderId =
          await ref.read(dispatchOfferProvider.notifier).accept(offer.id);
      if (!mounted) return;
      await ref
          .read(activeOrderProvider.notifier)
          .loadAcceptedOrder(riderOrderId);
      if (!mounted) return;
      unawaited(ref.read(dashboardStatsProvider.notifier).refresh());
      for (final filter in OrderHistoryFilter.values) {
        ref.invalidate(orderHistoryProvider(filter));
      }
      if (Get.currentRoute != AppRoutes.activeOrder) {
        Get.offNamed(AppRoutes.activeOrder);
      }
    } on ApiException catch (error) {
      await _handleError(error);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Something went wrong. Please try again.');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject(DispatchOfferModel offer) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(dispatchOfferProvider.notifier).reject(offer.id);
      if (mounted) Get.back();
    } on ApiException catch (error) {
      await _handleError(error);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Something went wrong. Please try again.');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleError(ApiException error) async {
    if (!mounted) return;
    if (error.statusCode == 401) {
      await ref.read(authSessionProvider.notifier).logout();
      if (mounted) Get.offAllNamed(AppRoutes.welcome);
      return;
    }
    AppSnackBar.error(context, error.message);
    setState(() => _isProcessing = false);
  }

  void _onCountdownExpired(DispatchOfferModel order) {
    if (!mounted || _expiryHandled) return;
    _expiryHandled = true;
    unawaited(
      ref.read(dispatchOfferProvider.notifier).handleDeadlineReached(order.id),
    );
    Get.offAllNamed(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final offerAsync = ref.watch(dispatchOfferProvider);
    ref.listen<AsyncValue<DispatchOfferModel?>>(dispatchOfferProvider,
        (previous, next) {
      if (_isProcessing || next.isLoading || next.hasError) return;
      if (next.valueOrNull == null &&
          Get.currentRoute == AppRoutes.incomingOffer) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              Navigator.of(context).canPop() &&
              Get.currentRoute == AppRoutes.incomingOffer) {
            Get.back();
          }
        });
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && mounted) {
          AppSnackBar.info(context,
              'This offer is still active. Accept or reject it to continue.');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 520,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: offerAsync.when(
              skipLoadingOnRefresh: true,
              loading: () => const _OfferLoadingView(),
              error: (error, _) => ErrorWidgetCustom(
                message: error is ApiException
                    ? error.message
                    : 'Could not load this delivery request.',
                onRetry: () =>
                    ref.read(dispatchOfferProvider.notifier).refresh(),
              ),
              data: (offer) {
                if (_isProcessing) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          'Accepting order...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Preparing pickup route to restaurant',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (offer == null || offer.isExpired) {
                  return const _NoOrderView();
                }
                return _OfferView(
                  offer: offer,
                  isProcessing: _isProcessing,
                  onExpired: () => _onCountdownExpired(offer),
                  onAccept: () => _accept(offer),
                  onReject: () => _reject(offer),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferView extends StatelessWidget {
  const _OfferView({
    required this.offer,
    required this.isProcessing,
    required this.onExpired,
    required this.onAccept,
    required this.onReject,
  });

  final DispatchOfferModel offer;
  final bool isProcessing;
  final VoidCallback onExpired;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final totalDistance = offer.distanceKm + offer.dropDistanceKm;
    final totalKmStr = totalDistance > 0
        ? totalDistance.toStringAsFixed(1)
        : (offer.distanceKm > 0 ? offer.distanceKm.toStringAsFixed(1) : '5.0');
    final estMinutes = ((totalDistance * 3.5) + 5).round().clamp(8, 45);
    final orderIdDisplay = offer.jobId.isNotEmpty
        ? (offer.jobId.length > 10
            ? '#ORD${offer.jobId.substring(0, 6).toUpperCase()}'
            : '#${offer.jobId.toUpperCase()}')
        : '#ORD${offer.id.length > 6 ? offer.id.substring(0, 6).toUpperCase() : "123456"}';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Header Bar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Bell Icon Container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.bellRing,
                    color: Color(0xFFF95721),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Center Title with Accent Dashes
              const Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DashAccent(isLeft: true),
                        SizedBox(width: 6),
                        Text(
                          'New Order',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF18181B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(width: 6),
                        _DashAccent(isLeft: false),
                      ],
                    ),
                    SizedBox(height: 1),
                    Text(
                      'You have received a new order',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF71717A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Right Countdown Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FAF0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC6F6D5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Auto reject in',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00875A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    CountdownTimer(
                      key: ValueKey(offer.id),
                      expiresAt: offer.expiresAt,
                      color: const Color(0xFF00875A),
                      onExpired: onExpired,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Earnings & Distance Hero Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E4E7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left: Your Earning
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR EARNING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF71717A),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.rupees(offer.payout),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF16A34A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8FAF0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Includes pickup',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00A859),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1,
                  height: 54,
                  color: const Color(0xFFE4E4E7),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),

                // Middle: Total Distance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL DISTANCE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF71717A),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalKmStr km',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF18181B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8FAF0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.clock,
                                size: 10, color: Color(0xFF00A859)),
                            const SizedBox(width: 3),
                            Text(
                              'Est. time $estMinutes min',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00A859),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: 3D Money/Wallet Illustration
                Image.asset(
                  AppAssets.earningsWallet3d,
                  width: 54,
                  height: 54,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    AppAssets.orderBagNew3d,
                    width: 54,
                    height: 54,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8FAF0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.wallet,
                        color: Color(0xFF00A859),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Map Route Preview Banner (matching screenshot style)
          const _RouteMapBanner(),
          const SizedBox(height: 10),

          // 4. Stops Timeline & Details Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E4E7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stop 1: Pickup
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF95721),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.shoppingBag,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        // Dotted Line
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: List.generate(
                              4,
                              (index) => Container(
                                width: 2,
                                height: 5,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCBD5E1),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'PICKUP RESTAURANT',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF95721),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              if (offer.distanceKm > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${offer.distanceKm.toStringAsFixed(1)} km away',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            offer.restaurantName,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            offer.restaurantAddress.isNotEmpty
                                ? offer.restaurantAddress
                                : 'Restaurant pickup location',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Stop 2: Drop-off
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A859),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.home,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'DELIVERY ADDRESS',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF00A859),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              if (offer.dropDistanceKm > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8FAF0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${offer.dropDistanceKm.toStringAsFixed(1)} km drop',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF00A859),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            offer.customerName,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            offer.userAddress.isNotEmpty
                                ? offer.userAddress
                                : 'Customer delivery address',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 12),

                // Order Meta Row (Payment & Order ID)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.creditCard,
                            size: 16, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PAYMENT TYPE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'Online Payment',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: orderIdDisplay));
                        AppSnackBar.success(
                            context, 'Order ID copied to clipboard');
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'ORDER ID',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.3,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  orderIdDisplay,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  LucideIcons.copy,
                                  size: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. Action Buttons (Decline & Accept Order)
          Row(
            children: [
              // Decline Button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: isProcessing ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFEE2E2)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.xCircle,
                          color: Color(0xFFDC2626),
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Decline',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Accept Order Button
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.checkCircle2,
                                color: Colors.white,
                                size: 19,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Accept Order',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DashAccent extends StatelessWidget {
  const _DashAccent({required this.isLeft});

  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: !isLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 2.5,
            decoration: BoxDecoration(
              color: const Color(0xFFF95721),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 2),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 2.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFF95721),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 6,
                height: 2.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFF95721),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteMapBanner extends StatelessWidget {
  const _RouteMapBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            // Soft realistic street grid background
            Positioned.fill(
              child: CustomPaint(
                painter: _StreetGridPainter(),
              ),
            ),

            // Dashed Curved Route
            Positioned.fill(
              child: CustomPaint(
                painter: _CurvedRoutePainter(),
              ),
            ),

            // Left Pickup Pin Marker
            Positioned(
              left: 22,
              top: 14,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFF95721),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.shoppingBag,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),

            // Right Drop-off Pin Marker
            Positioned(
              right: 22,
              bottom: 14,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF00A859),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.home,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvedRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00A859)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const start = Offset(42, 28);
    final end = Offset(size.width - 42, size.height - 28);

    path.moveTo(start.dx, start.dy);
    path.cubicTo(
      size.width * 0.32,
      size.height * 0.82,
      size.width * 0.65,
      size.height * 0.18,
      end.dx,
      end.dy,
    );

    // Draw dashed line effect
    final dashPath = Path();
    double distance = 0.0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        const length = 5.0;
        final next = distance + length;
        if (next <= metric.length) {
          dashPath.addPath(
            metric.extractPath(distance, next),
            Offset.zero,
          );
        }
        distance += length + 4.0; // 4px dash spacing
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StreetGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF7F9FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadBorder = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 5.5;

    final roadSurface = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0;

    // Road 1
    canvas.drawLine(
        Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.45), roadBorder);
    canvas.drawLine(
        Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.45), roadSurface);

    // Road 2
    canvas.drawLine(
        Offset(size.width * 0.45, 0), Offset(size.width * 0.55, size.height), roadBorder);
    canvas.drawLine(
        Offset(size.width * 0.45, 0), Offset(size.width * 0.55, size.height), roadSurface);

    // Road 3
    canvas.drawLine(
        Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.75), roadBorder);
    canvas.drawLine(
        Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.75), roadSurface);

    // River / Park Area
    final greenZone = Paint()..color = const Color(0xFFE2F8EB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.52, 4, size.width * 0.36, size.height * 0.32),
        const Radius.circular(6),
      ),
      greenZone,
    );

    final riverZone = Paint()..color = const Color(0xFFE0F2FE);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.82, 2, size.width * 0.16, size.height * 0.4),
        const Radius.circular(6),
      ),
      riverZone,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OfferLoadingView extends StatelessWidget {
  const _OfferLoadingView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
}

class _NoOrderView extends StatelessWidget {
  const _NoOrderView();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EmptyState(
            icon: LucideIcons.inbox,
            message: 'This order is no longer available.',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Get.offAllNamed(AppRoutes.dashboard),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back to dashboard',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      );
}

