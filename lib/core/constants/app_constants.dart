class AppConstants {
  AppConstants._();

  static const appName = 'Qikzoo Delivery Partner';
  static const otpLength = 4;
  static const otpResendSeconds = 30;

  /// How often `RiderPollingController` polls `GET /rider/dispatch/current`
  /// for a new offer and refreshes the active order, for the lifetime of an
  /// authenticated session (not tied to any one screen being mounted — see
  /// that provider's doc comment). Safe to run unconditionally (online or
  /// not) since a rider who isn't AVAILABLE is never assigned an attempt
  /// server-side — see DispatchEngineService's AVAILABLE-only Redis GEO
  /// candidate pool.
  static const dispatchOfferPollInterval = Duration(seconds: 8);
}
