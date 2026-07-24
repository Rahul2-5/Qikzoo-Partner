class AppConstants {
  AppConstants._();

  static const appName = 'Qikzoo Delivery Partner';
  static const mockNetworkDelay = Duration(milliseconds: 400);
  static const otpLength = 4;
  static const otpResendSeconds = 30;

  /// How often the dashboard polls `GET /rider/dispatch/current` for a new
  /// offer while mounted. Safe to run unconditionally (online or not) since
  /// a rider who isn't AVAILABLE is never assigned an attempt server-side —
  /// see DispatchEngineService's AVAILABLE-only Redis GEO candidate pool.
  static const dispatchOfferPollInterval = Duration(seconds: 8);

  /// How often the active-order screen re-fetches while an order is
  /// in-flight, so a status change made elsewhere (e.g. the order being
  /// cancelled by support) is picked up without the rider needing to
  /// pull-to-refresh.
  static const activeOrderPollInterval = Duration(seconds: 15);
}
