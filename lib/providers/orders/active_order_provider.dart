import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/orders/rider_order_model.dart';
import '../../repositories/orders/rider_orders_repository.dart';

/// The rider's single active (not yet delivered/cancelled) order, if any —
/// `null` means there is none right now. A rider can only hold one at a
/// time (dispatch requires AVAILABLE, which `acceptAssignment` immediately
/// flips to BUSY), so the first entry of `GET /rider/orders/current` is
/// always the one that matters.
class ActiveOrderNotifier extends AsyncNotifier<RiderOrderModel?> {
  @override
  Future<RiderOrderModel?> build() => _fetch();

  Future<RiderOrderModel?> _fetch() async {
    final current = await ref.read(riderOrdersRepositoryProvider).getCurrent();
    return current.isEmpty ? null : current.first;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  /// Every action below deliberately does NOT go through AsyncValue.guard:
  /// a failed action (wrong QR, expired OTP, a stale status because
  /// another process already advanced it) must not blow away the still-
  /// displayed order card with a full-screen error — the exception
  /// propagates to the caller, which shows a snackbar and leaves the
  /// current order visible so the rider can retry the same action.
  Future<void> markArrived(String riderOrderId) async {
    await ref.read(riderOrdersRepositoryProvider).markArrived(riderOrderId);
    await _refreshAfterAction(riderOrderId);
  }

  Future<void> scanPickupQr(String riderOrderId, String token) async {
    await ref.read(riderOrdersRepositoryProvider).scanPickupQr(riderOrderId, token);
    await _refreshAfterAction(riderOrderId);
  }

  Future<void> pickupSuccess(String riderOrderId) async {
    await ref.read(riderOrdersRepositoryProvider).pickupSuccess(riderOrderId);
    await _refreshAfterAction(riderOrderId);
  }

  Future<void> startDelivery(String riderOrderId) async {
    await ref.read(riderOrdersRepositoryProvider).startDelivery(riderOrderId);
    await _refreshAfterAction(riderOrderId);
  }

  Future<void> completeDelivery(String riderOrderId, String code) async {
    await ref.read(riderOrdersRepositoryProvider).completeDelivery(riderOrderId, code);
    // A completed delivery is no longer "active" — the backend excludes
    // DELIVERED from `current`, so re-fetching naturally clears it.
    state = AsyncData(await _fetch());
  }

  Future<void> cancel(String riderOrderId, String reason) async {
    await ref.read(riderOrdersRepositoryProvider).cancel(riderOrderId, reason);
    state = AsyncData(await _fetch());
  }

  /// The write endpoints (`arrived`/`scan-pickup-qr`/`pickup-success`/
  /// `start-delivery`) return the bare RiderOrder row, not the enriched
  /// restaurant/order/statusHistory shape `getOne` returns — so every
  /// action re-fetches the detail view rather than trusting its own
  /// response, same discipline as DispatchEngineService.acceptAssignment's
  /// caller needing a follow-up fetch.
  Future<void> _refreshAfterAction(String riderOrderId) async {
    final updated = await ref.read(riderOrdersRepositoryProvider).getOne(riderOrderId);
    state = AsyncData(updated);
  }
}

final activeOrderProvider =
    AsyncNotifierProvider<ActiveOrderNotifier, RiderOrderModel?>(
  ActiveOrderNotifier.new,
);
