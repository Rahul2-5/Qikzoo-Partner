import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/dio_service.dart';
import '../../core/navigation/next_onboarding_step_resolver.dart';
import '../../repositories/authentication/auth_repository.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../repositories/onboarding_status/onboarding_status_repository.dart';
import '../../models/authentication/auth_session_model.dart';
import '../../models/authentication/session_restore_outcome.dart';
import '../core/api_providers.dart';

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
      () => ref.read(authRepositoryProvider).verifyOtp(phoneNumber, otp, name: name),
    );
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
          partnerId: profile.id,
          token: accessToken,
          isAuthenticated: true,
        ),
      );
      return SessionRestoreResult(
        onboarding.isActive
            ? SessionRestoreOutcome.active
            : SessionRestoreOutcome.needsOnboarding,
        route: NextOnboardingStepResolver.resolve(onboarding),
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
  }

  /// Ends the session: best-effort revokes it server-side, always clears
  /// local tokens, and resets [state] to signed-out.
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthSessionModel.empty);
  }
}

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, AuthSessionModel>(
  AuthSessionNotifier.new,
);
