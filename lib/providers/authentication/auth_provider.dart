import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/dio_service.dart';
import '../../core/location/rider_background_location_service.dart';
import '../../core/navigation/next_onboarding_step_resolver.dart';
import '../../core/push/push_service.dart';
import '../../repositories/authentication/auth_repository.dart';
import '../location/rider_location_provider.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../repositories/onboarding_status/onboarding_status_repository.dart';
import '../../models/authentication/auth_session_model.dart';
import '../../models/authentication/session_restore_outcome.dart';
import '../core/api_providers.dart';
import '../dashboard/dashboard_provider.dart';
import '../orders/active_order_provider.dart';
import '../orders/dispatch_offer_provider.dart';
import '../notifications/notifications_provider.dart';
import '../polling/rider_polling_controller.dart';
import '../profile/profile_provider.dart';
import '../wallet/wallet_provider.dart';
import '../earnings/earnings_provider.dart';
import '../bank_details/bank_details_provider.dart';
import '../verification_status/verification_status_provider.dart';

/// UI state: the phone number currently being entered/verified.
final phoneNumberUiProvider = StateProvider<String>((ref) => '');

/// UI state: the full name entered during signup — the backend requires it
/// to create a new Rider account on first verify-otp (see
/// `RiderAuthService.verifyOtpLogin`); unused/ignored on login.
final signupNameUiProvider = StateProvider<String>((ref) => '');

/// Domain state: the authenticated session.
class AuthSessionNotifier extends AsyncNotifier<AuthSessionModel> {
  @override
  Future<AuthSessionModel> build() async => AuthSessionModel.empty;

  Future<void> verifyOtp(String phoneNumber, String otp, {String? name}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .verifyOtp(phoneNumber, otp, name: name),
    );
    if (state.valueOrNull?.isAuthenticated == true) {
      // A previous session (this rider logging back in, or a different
      // rider on a shared device) may have left stale AsyncNotifierProvider
      // state cached — force every session-scoped provider to re-fetch from
      // the backend rather than risk the dashboard rendering leftover data
      // from before this login.
      _invalidateSessionScopedState();
      unawaited(PushService.instance.registerCurrentToken());
    }
  }

  /// Drops any cached availability/active-order/offer/notification state so
  /// the next read is a genuine backend fetch, never a stale carry-over from
  /// a previous session in this same app process. Called on every
  /// authenticated entry point (fresh login, successful session restore) and
  /// on logout — backend remains the sole source of truth; this never
  /// fabricates or guesses a value, it only clears the cache so the real one
  /// gets fetched.
  void _invalidateSessionScopedState() {
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(activeOrderProvider);
    ref.invalidate(dispatchOfferProvider);
    ref.invalidate(notificationsProvider);
    // Previously omitted — a rider logging out and a different rider
    // logging in on the same device/app process could see the PREVIOUS
    // rider's name/photo, wallet balance, transaction history, earnings,
    // and masked bank details until a manual pull-to-refresh.
    ref.invalidate(profileProvider);
    ref.invalidate(ratingProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(earningsSummaryProvider);
    ref.invalidate(earningsHistoryProvider);
    ref.invalidate(bankDetailsProvider);
    ref.invalidate(verificationStepsProvider);
  }

  /// Called once on app start. If a refresh token is stored, silently
  /// rotates it, fetches the rider's profile and onboarding status, and
  /// updates [state] so the rest of the app sees an authenticated session
  /// without ever showing the login screen again. Never throws — every
  /// outcome (including no/expired token and network failure) is reported
  /// through the returned [SessionRestoreResult] instead.
  ///
  /// The onboarding status is fetched exactly once here and immediately
  /// resolved to a concrete route via [NextOnboardingStepResolver] — the
  /// same resolver every onboarding screen uses — so the caller (the
  /// splash screen) never re-fetches it or re-implements its own routing.
  Future<SessionRestoreResult> restoreSession() async {
    try {
      final storage = ref.read(secureTokenStorageProvider);
      final hasRefreshToken = await storage.getRefreshToken();
      if (hasRefreshToken == null || hasRefreshToken.isEmpty) {
        state = const AsyncData(AuthSessionModel.empty);
        return const SessionRestoreResult(SessionRestoreOutcome.loggedOut);
      }

      final dioService = ref.read(dioServiceProvider);
      final refreshResult = await dioService.refreshSession();

      switch (refreshResult) {
        case SessionRefreshResult.networkError:
          return const SessionRestoreResult(SessionRestoreOutcome.offline);
        case SessionRefreshResult.invalidToken:
          state = const AsyncData(AuthSessionModel.empty);
          return const SessionRestoreResult(SessionRestoreOutcome.loggedOut);
        case SessionRefreshResult.success:
          break;
      }

      try {
        final profile = await ref.read(profileRepositoryProvider).getProfile();
        final onboarding =
            await ref.read(onboardingStatusRepositoryProvider).getStatus();
        final accessToken = await storage.getAccessToken() ?? '';

        state = AsyncData(
          AuthSessionModel(
            partnerId: profile.publicRiderId ?? '',
            token: accessToken,
            isAuthenticated: true,
          ),
        );
        // See [_invalidateSessionScopedState] — guarantees the dashboard's
        // first read after a session restore is a fresh backend fetch, not
        // whatever an earlier app run left cached.
        _invalidateSessionScopedState();
        unawaited(PushService.instance.registerCurrentToken());
        return SessionRestoreResult(
          onboarding.isActive
              ? SessionRestoreOutcome.active
              : SessionRestoreOutcome.needsOnboarding,
          route:
              NextOnboardingStepResolver.resolve(onboarding, profile: profile),
        );
      } on ApiException catch (error) {
        if (error.statusCode == 401) {
          await ref.read(authRepositoryProvider).logout();
          state = const AsyncData(AuthSessionModel.empty);
          return const SessionRestoreResult(SessionRestoreOutcome.loggedOut);
        }
        // Any other failure (timeout, no connection, 5xx, ...) fetching
        // profile/onboarding after a *successful* token refresh is a
        // connectivity problem, not a session problem — leave the stored
        // tokens alone so a retry can pick up where this left off.
        return const SessionRestoreResult(SessionRestoreOutcome.offline);
      }
    } catch (_) {
      state = const AsyncData(AuthSessionModel.empty);
      return const SessionRestoreResult(SessionRestoreOutcome.loggedOut);
    }
  }

  /// Ends the session: best-effort revokes it server-side, always clears
  /// local tokens, and resets [state] to signed-out.
  ///
  /// Stops the location ping loop and the dispatch-offer/active-order poll
  /// first, centrally, so every logout path (the Profile screen's explicit
  /// "Log out", and every screen's own forced-logout-on-401 handler)
  /// reliably tears them down — no per-screen call site needs to remember
  /// to do it itself.
  Future<void> logout() async {
    ref.read(riderLocationControllerProvider.notifier).stop();
    ref.read(riderPollingControllerProvider.notifier).stop();
    await RiderBackgroundLocationService.instance.stop();
    await PushService.instance.removeCurrentToken();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthSessionModel.empty);
    // Clear this rider's cached state completely — the next login (same
    // rider or a different one on this device) must never see it.
    _invalidateSessionScopedState();
  }
}

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, AuthSessionModel>(
  AuthSessionNotifier.new,
);
