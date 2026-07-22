import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/dio_service.dart';
import '../../repositories/authentication/auth_repository.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../repositories/onboarding_status/onboarding_status_repository.dart';
import '../../models/authentication/auth_session_model.dart';
import '../../models/authentication/session_restore_outcome.dart';
import '../core/api_providers.dart';

/// UI state: the phone number currently being entered/verified.
final phoneNumberUiProvider = StateProvider<String>((ref) => '');

/// Domain state: the authenticated session.
class AuthSessionNotifier extends AsyncNotifier<AuthSessionModel> {
  @override
  Future<AuthSessionModel> build() async => AuthSessionModel.empty;

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).verifyOtp(phoneNumber, otp),
    );
  }

  /// Called once on app start. If a refresh token is stored, silently
  /// rotates it, fetches the rider's profile and onboarding status, and
  /// updates [state] so the rest of the app sees an authenticated session
  /// without ever showing the login screen again. Never throws — every
  /// outcome (including no/expired token and network failure) is reported
  /// through the returned [SessionRestoreOutcome] instead.
  Future<SessionRestoreOutcome> restoreSession() async {
    final storage = ref.read(secureTokenStorageProvider);
    final hasRefreshToken = await storage.getRefreshToken();
    if (hasRefreshToken == null || hasRefreshToken.isEmpty) {
      state = const AsyncData(AuthSessionModel.empty);
      return SessionRestoreOutcome.loggedOut;
    }

    final dioService = ref.read(dioServiceProvider);
    final refreshResult = await dioService.refreshSession();

    switch (refreshResult) {
      case SessionRefreshResult.networkError:
        return SessionRestoreOutcome.offline;
      case SessionRefreshResult.invalidToken:
        state = const AsyncData(AuthSessionModel.empty);
        return SessionRestoreOutcome.loggedOut;
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
      return onboarding.isActive
          ? SessionRestoreOutcome.active
          : SessionRestoreOutcome.needsOnboarding;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await ref.read(authRepositoryProvider).logout();
        state = const AsyncData(AuthSessionModel.empty);
        return SessionRestoreOutcome.loggedOut;
      }
      // Any other failure (timeout, no connection, 5xx, ...) fetching
      // profile/onboarding after a *successful* token refresh is a
      // connectivity problem, not a session problem — leave the stored
      // tokens alone so a retry can pick up where this left off.
      return SessionRestoreOutcome.offline;
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
