class ApiEndpoints {
  ApiEndpoints._();

  static const riderRequestOtp = '/rider/auth/request-otp';
  static const riderVerifyOtp = '/rider/auth/verify-otp';
  static const riderRefresh = '/rider/auth/refresh';
  static const riderLogout = '/rider/auth/logout';

  static const riderProfile = '/rider/profile';
  static const riderProfilePhoto = '/rider/profile/photo';
  static const riderKyc = '/rider/kyc';
  static const riderKycGovernmentIdDocument =
      '/rider/kyc/documents/government-id';
  static const riderKycDrivingLicenseDocument =
      '/rider/kyc/documents/driving-license';
  static const riderVehicles = '/rider/vehicles';
  static String riderVehicleActivate(String vehicleId) =>
      '/rider/vehicles/$vehicleId/activate';
  static String riderVehicleInsuranceDocument(String vehicleId) =>
      '/rider/vehicles/$vehicleId/documents/insurance';
  static String riderVehicleRcDocument(String vehicleId) =>
      '/rider/vehicles/$vehicleId/documents/rc';

  static const riderOnboarding = '/rider/onboarding';
  static const riderOnboardingSubmit = '/rider/onboarding/submit';
  static const riderOnboardingReapply = '/rider/onboarding/reapply';
  static const riderAvailability = '/rider/availability';
  static const riderAvailabilityOnline = '/rider/availability/online';
  static const riderAvailabilityOffline = '/rider/availability/offline';
  static const riderOrders = '/rider/orders';
  static const riderOrdersCurrent = '/rider/orders/current';
  static const riderOrdersHistory = '/rider/orders/history';
  static String riderOrderDetail(String riderOrderId) =>
      '/rider/orders/$riderOrderId';
  static String riderOrderArrived(String riderOrderId) =>
      '/rider/orders/$riderOrderId/arrived';
  static String riderOrderScanPickupQr(String riderOrderId) =>
      '/rider/orders/$riderOrderId/scan-pickup-qr';
  static String riderOrderPickupSuccess(String riderOrderId) =>
      '/rider/orders/$riderOrderId/pickup-success';
  static String riderOrderStartDelivery(String riderOrderId) =>
      '/rider/orders/$riderOrderId/start-delivery';
  static String riderOrderCompleteDelivery(String riderOrderId) =>
      '/rider/orders/$riderOrderId/complete-delivery';
  static String riderOrderCancel(String riderOrderId) =>
      '/rider/orders/$riderOrderId/cancel';

  static const riderDispatchCurrent = '/rider/dispatch/current';
  static String riderDispatchAccept(String attemptId) =>
      '/rider/dispatch/$attemptId/accept';
  static String riderDispatchReject(String attemptId) =>
      '/rider/dispatch/$attemptId/reject';

  static const riderEarnings = '/rider/earnings';
  static const riderEarningsSummary = '/rider/earnings/summary';
  static const riderWallet = '/rider/wallet';
}
