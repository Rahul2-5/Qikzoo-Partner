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
  static const riderOnboarding = '/rider/onboarding';
  static const riderAvailability = '/rider/availability';
  static const riderOrders = '/rider/orders';
  static const riderEarnings = '/rider/earnings';
  static const riderWallet = '/rider/wallet';
}
