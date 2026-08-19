import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/dispatch_offer_cache.dart';
import '../../models/orders/dispatch_offer_model.dart';
import '../../repositories/orders/dispatch_repository.dart';

/// The rider's current outstanding dispatch offer, if any. Polled by
/// `RiderPollingController` for the lifetime of an authenticated session,
/// not by any one screen — see that provider's doc comment; this notifier
/// itself only holds state and performs the fetch/accept/reject calls.
class DispatchOfferNotifier extends AsyncNotifier<DispatchOfferModel?> {
  DispatchOfferStore get _cache => ref.read(dispatchOfferStoreProvider);
  int _operationVersion = 0;
  final Set<String> _completedOfferIds = <String>{};

  DispatchOfferModel? _actionable(DispatchOfferModel? order) {
    if (order == null ||
        _completedOfferIds.contains(order.id) ||
        order.status != DispatchAttemptStatus.waitingRider ||
        order.isExpired) {
      return null;
    }
    return order;
  }

  @override
  Future<DispatchOfferModel?> build() async {
    ref.watch(dispatchRepositoryProvider);
    final cached = _actionable(await _cache.read());
    if (cached != null) {
      // Render the restored card first; reconcile with the backend without
      // replacing it by a full-screen loader.
      unawaited(refresh());
      return cached;
    }
    final offer = _actionable(
      await ref.read(dispatchRepositoryProvider).getCurrentOffer(),
    );
    if (offer != null) await _cache.write(offer);
    return offer;
  }

  Future<void> refresh() async {
    final operationVersion = ++_operationVersion;
    final previous = state.valueOrNull;
    try {
      final offer = _actionable(
        await ref.read(dispatchRepositoryProvider).getCurrentOffer(),
      );
      // Accept/reject/expiry may have completed while this request was in
      // flight. Never let that older response republish the stale offer.
      if (operationVersion != _operationVersion) return;
      if (offer == null) {
        await _cache.clear();
      } else {
        await _cache.write(offer);
      }
      if (operationVersion != _operationVersion) return;
      state = AsyncData(offer);
    } catch (error, stackTrace) {
      if (operationVersion != _operationVersion) return;
      // Stale-while-revalidate: a network interruption must not make a still
      // valid, actionable card disappear into a loader/error page.
      if (previous != null && !previous.isExpired) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  /// Deliberately does NOT go through AsyncValue.guard — a failed accept
  /// (offer already taken, rider no longer AVAILABLE, expired) must not
  /// wipe the still-valid offer state out from under the countdown UI; the
  /// exception propagates to the caller, which shows a snackbar and lets
  /// the rider retry or let the countdown continue.
  Future<String> accept(String attemptId) async {
    ++_operationVersion;
    final riderOrderId =
        await ref.read(dispatchRepositoryProvider).accept(attemptId);
    _completedOfferIds.add(attemptId);
    await _cache.clear();
    state = const AsyncData(null);
    return riderOrderId;
  }

  Future<void> reject(String attemptId) async {
    ++_operationVersion;
    await ref.read(dispatchRepositoryProvider).reject(attemptId);
    _completedOfferIds.add(attemptId);
    await _cache.clear();
    state = const AsyncData(null);
  }

  /// Removes the incoming-order card at the absolute deadline supplied by the
  /// backend. The dispatch engine owns expiry and reassignment; the follow-up
  /// refresh only reconciles this UI with that authoritative state.
  Future<void> handleDeadlineReached(String attemptId) async {
    if (state.valueOrNull?.id != attemptId) return;
    ++_operationVersion;
    _completedOfferIds.add(attemptId);
    await _cache.clear();
    state = const AsyncData(null);
    unawaited(refresh());
  }
}

final dispatchOfferProvider =
    AsyncNotifierProvider<DispatchOfferNotifier, DispatchOfferModel?>(
  DispatchOfferNotifier.new,
);

final dispatchOfferStoreProvider = Provider<DispatchOfferStore>(
  (ref) => DispatchOfferCache(),
);
