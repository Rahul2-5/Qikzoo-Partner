/// Where the app should land after trying to silently restore a session on
/// startup (see `AuthSessionNotifier.restoreSession`).
enum SessionRestoreOutcome {
  /// Refresh + profile + onboarding status all succeeded and the rider's
  /// account is fully active — go straight into the app, no login shown.
  active,

  /// Refresh + profile + onboarding status all succeeded but the rider's
  /// account isn't active yet (onboarding still pending/under review) —
  /// land on the onboarding/verification status flow, not the dashboard.
  needsOnboarding,

  /// No refresh token was stored, or it was invalid/expired — the local
  /// session has been cleared; show the login flow.
  loggedOut,

  /// The refresh token itself may still be valid, but the network/server
  /// was unreachable — the stored session is left untouched so the rider
  /// isn't logged out just for being offline. The caller should offer a
  /// retry rather than navigate to either the app or the login flow.
  offline,
}

/// The full result of [AuthSessionNotifier.restoreSession]: the coarse
/// [outcome] plus — only for [SessionRestoreOutcome.active] and
/// [SessionRestoreOutcome.needsOnboarding], where an [OnboardingStatusModel]
/// was actually fetched — the exact destination [route] already resolved
/// through `NextOnboardingStepResolver`. Callers (the splash screen) must
/// navigate to [route] rather than deriving their own mapping, so there is
/// only one place in the app that turns onboarding status into a route.
///
/// [route] is null for [SessionRestoreOutcome.loggedOut] and
/// [SessionRestoreOutcome.offline]: neither reaches the point of fetching
/// an onboarding status, so there is nothing for the resolver to act on —
/// the caller keeps its own fixed handling for those two (e.g. navigate to
/// login, or show a retry).
class SessionRestoreResult {
  final SessionRestoreOutcome outcome;
  final String? route;

  const SessionRestoreResult(this.outcome, {this.route});
}
