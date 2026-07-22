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
  static const riderOrders = '/rider/orders';
  static const riderEarnings = '/rider/earnings';
  static const riderWallet = '/rider/wallet';
}
