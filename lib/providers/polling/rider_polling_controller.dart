import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/push/push_service.dart';
import '../../core/routes/app_routes.dart';
import '../../models/orders/dispatch_offer_model.dart';
import '../../models/orders/order_history_page_model.dart';
import '../../models/orders/rider_order_model.dart';
import '../dashboard/dashboard_provider.dart';
import '../orders/active_order_provider.dart';
import '../orders/dispatch_offer_provider.dart';
import '../orders/order_history_provider.dart';

/// Keeps dispatch-offer, active-order, dashboard-stats and order-history
/// state fresh for the lifetime of an authenticated rider session —
/// independent of which tab route currently happens to be mounted.
///
/// Tab navigation in this app replaces the whole GetX route stack
/// (`Get.offAllNamed`, see `app_bottom_nav.dart`'s `navigateToTab`), which
/// used to fully dispose whichever screen owned the poll timer
/// (`DashboardHomeScreen`) the instant the rider switched tabs — silently
/// stopping dispatch-offer detection and active-order sync for anyone not
/// looking at the Home tab. Living in a plain (non-autoDispose) `Notifier`
/// instead means the single timer survives every tab switch, the same way
/// `riderLocationControllerProvider` already survives them for GPS
/// tracking — modelled directly on that provider's shape.
///
/// [start]/[stop] bracket an authenticated session (called from
/// `DashboardHomeScreen.initState` — the same timing `_startOfferPolling`
/// used before — and from `AuthSessionNotifier.logout`, alongside the
/// location controller's own stop call). [handleResume]/[handlePause] are
/// driven by the app-root lifecycle observer in `app.dart`, not tied to any
/// one screen, so backgrounding/foregrounding the app behaves the same
/// regardless of which tab was on screen when it happened.
class RiderPollingController extends Notifier<bool> {
  Timer? _pollTimer;
  String? _lastHandledOfferId;
  ProviderSubscription<AsyncValue<DispatchOfferModel?>>? _offerSub;
  ProviderSubscription<AsyncValue<RiderOrderModel?>>? _activeOrderSub;

  @override
  bool build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
      _offerSub?.close();
      _activeOrderSub?.close();
    });
    return false;
  }

  /// Idempotent — safe to call every time `DashboardHomeScreen` mounts,
  /// whether or not the timer is already running.
  ///
  /// The `dispatchOfferProvider`/`activeOrderProvider` listeners are wired
  /// up here (not in [build]) so that merely reading this controller's
  /// notifier — which happens on every app resume/pause via
  /// `RiderPollingLifecycleObserver` — never forces those providers to
  /// eagerly fetch before a rider session has actually started polling.
  void start() {
    if (state) {
      _restartTimer();
      return;
    }
    state = true;
    _offerSub = ref.listen<AsyncValue<DispatchOfferModel?>>(
      dispatchOfferProvider,
      _onOfferChanged,
    );
    _activeOrderSub = ref.listen<AsyncValue<RiderOrderModel?>>(
      activeOrderProvider,
      _onActiveOrderChanged,
    );
    _restartTimer();
  }

  void stop() {
    state = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _offerSub?.close();
    _offerSub = null;
    _activeOrderSub?.close();
    _activeOrderSub = null;
  }

  void handleResume() {
    if (!state) return; // never started (still on auth/onboarding) — no-op
    ref.read(dispatchOfferProvider.notifier).refresh();
    ref.read(dashboardStatsProvider.notifier).refresh();
    _restartTimer();
  }

  void handlePause() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _restartTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      AppConstants.dispatchOfferPollInterval,
      (_) {
        ref.read(dispatchOfferProvider.notifier).refresh();
        // Also keeps the active order in sync with a restaurant-side
        // cancel/complete that happened while the rider was looking at
        // any tab, not just the (now-removed) Active Order screen poll.
        ref.read(activeOrderProvider.notifier).refresh();
      },
    );
  }

  void _onOfferChanged(
    AsyncValue<DispatchOfferModel?>? previous,
    AsyncValue<DispatchOfferModel?> next,
  ) {
    final offer = next.valueOrNull;
    if (offer == null || offer.id == _lastHandledOfferId) return;
    _lastHandledOfferId = offer.id;
    // Polling is the only *guaranteed* offer-detection path (FCM is best-
    // effort — see PushService.showOfferDetectedAlert) — a rider who isn't
    // already staring at the screen needs an audible/haptic alert here, not
    // just a silent route change, or a real offer can expire unnoticed.
    unawaited(PushService.instance.showOfferDetectedAlert(
      attemptId: offer.id,
      restaurantName: offer.restaurantName,
    ));
    Get.toNamed(AppRoutes.incomingOffer);
  }

  /// Reacts whenever the poll above (or any other trigger) reads a changed
  /// active-order state — most importantly, an order that just vanished
  /// because the RESTAURANT cancelled it while the rider was on any tab.
  /// Refreshes dashboard stats (BUSY -> AVAILABLE won't show itself) and
  /// drops the Orders tab's cached history pages so a newly-cancelled/
  /// completed order isn't left showing under "Ongoing" from a stale fetch.
  void _onActiveOrderChanged(
    AsyncValue<RiderOrderModel?>? previous,
    AsyncValue<RiderOrderModel?> next,
  ) {
    if (previous?.valueOrNull == next.valueOrNull) return;
    ref.read(dashboardStatsProvider.notifier).refresh();
    for (final filter in OrderHistoryFilter.values) {
      ref.invalidate(orderHistoryProvider(filter));
    }
  }
}

final riderPollingControllerProvider =
    NotifierProvider<RiderPollingController, bool>(RiderPollingController.new);
