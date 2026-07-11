import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/authentication/otp_model.dart';
import '../../models/authentication/auth_session_model.dart';

abstract class AuthRepository {
  Future<OtpModel> requestOtp(String phoneNumber);
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp);
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<OtpModel> requestOtp(String phoneNumber) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return OtpModel(
      phoneNumber: phoneNumber,
      isVerified: false,
      expiresAt: DateTime.now().add(const Duration(seconds: AppConstants.otpResendSeconds)),
    );
  }

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return const AuthSessionModel(
      partnerId: 'partner_mock_001',
      token: 'mock_token_abc123',
      isAuthenticated: true,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => MockAuthRepository());
