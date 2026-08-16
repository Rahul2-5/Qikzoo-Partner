import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/orders/dispatch_offer_model.dart';
import '../../repositories/orders/dispatch_repository.dart';

/// The rider's current outstanding dispatch offer, if any. Polled by
/// `RiderPollingController` for the lifetime of an authenticated session,
/// not by any one screen — see that provider's doc comment; this notifier
/// itself only holds state and performs the fetch/accept/reject calls.
class DispatchOfferNotifier extends AsyncNotifier<DispatchOfferModel?> {
  @override
  Future<DispatchOfferModel?> build() =>
      ref.watch(dispatchRepositoryProvider).getCurrentOffer();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(dispatchRepositoryProvider).getCurrentOffer(),
    );
  }

  /// Deliberately does NOT go through AsyncValue.guard — a failed accept
  /// (offer already taken, rider no longer AVAILABLE, expired) must not
  /// wipe the still-valid offer state out from under the countdown UI; the
  /// exception propagates to the caller, which shows a snackbar and lets
  /// the rider retry or let the countdown continue.
  Future<void> accept(String attemptId) async {
    await ref.read(dispatchRepositoryProvider).accept(attemptId);
    state = const AsyncData(null);
  }

  Future<void> reject(String attemptId) async {
    await ref.read(dispatchRepositoryProvider).reject(attemptId);
    state = const AsyncData(null);
  }
}

final dispatchOfferProvider =
    AsyncNotifierProvider<DispatchOfferNotifier, DispatchOfferModel?>(
  DispatchOfferNotifier.new,
);
