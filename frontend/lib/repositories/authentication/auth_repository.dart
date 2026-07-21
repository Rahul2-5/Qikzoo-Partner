import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../models/authentication/otp_model.dart';
import '../../models/authentication/auth_session_model.dart';
import '../../providers/core/api_providers.dart';

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
      expiresAt: DateTime.now()
          .add(const Duration(seconds: AppConstants.otpResendSeconds)),
    );
  }

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp) async {
    final isValidOtp = RegExp(
      '^\\d{${AppConstants.otpLength}}\$',
    ).hasMatch(otp);
    if (!isValidOtp) {
      throw const FormatException('OTP must contain exactly 4 digits.');
    }
    await Future.delayed(AppConstants.mockNetworkDelay);
    return const AuthSessionModel(
      partnerId: 'partner_mock_001',
      token: 'mock_token_abc123',
      isAuthenticated: true,
    );
  }
}

class DioAuthRepository implements AuthRepository {
  const DioAuthRepository({
    required ApiClient apiClient,
    required SecureTokenStorage storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  final ApiClient _apiClient;
  final SecureTokenStorage _storage;

  @override
  Future<OtpModel> requestOtp(String phoneNumber) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderRequestOtp,
      data: {'phone': phoneNumber.trim()},
    );

    final data = _responseData(response.data);
    final expiresAt = _readDateTime(data, ['expiresAt', 'otpExpiresAt']) ??
        DateTime.now()
            .add(const Duration(seconds: AppConstants.otpResendSeconds));

    return OtpModel(
      phoneNumber: phoneNumber.trim(),
      isVerified: false,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderVerifyOtp,
      data: {
        'phone': phoneNumber.trim(),
        'code': otp.trim(),
      },
    );

    final data = _responseData(response.data);
    final accessToken =
        _readToken(data, ['accessToken', 'access_token', 'token']);
    final refreshToken = _readToken(data, ['refreshToken', 'refresh_token']);
    final partnerId = _readString(data, ['partnerId', 'riderId', 'id']) ??
        _readString(_readMap(data, 'rider'), ['id', '_id']);

    if (accessToken == null || accessToken.isEmpty) {
      throw const FormatException('Login response did not include a token.');
    }

    try {
      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (_) {
      // Do not block navigation if secure storage has a platform issue.
      // Protected API calls will still require storage to be available later.
    }

    return AuthSessionModel(
      partnerId: partnerId ?? '',
      token: accessToken,
      isAuthenticated: true,
    );
  }

  Map<String, dynamic> _responseData(Map<String, dynamic>? body) {
    if (body == null) return const {};
    final nestedData = body['data'];
    if (nestedData is Map<String, dynamic>) return nestedData;
    return body;
  }

  Map<String, dynamic>? _readMap(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is Map<String, dynamic> ? value : null;
  }

  String? _readString(Map<String, dynamic>? data, List<String> keys) {
    if (data == null) return null;
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  String? _readToken(Map<String, dynamic> data, List<String> keys) {
    final directToken = _readString(data, keys);
    if (directToken != null) return directToken;

    for (final containerKey in ['tokens', 'auth', 'session']) {
      final container = _readMap(data, containerKey);
      final nestedToken = _readString(container, keys);
      if (nestedToken != null) return nestedToken;
    }

    return null;
  }

  DateTime? _readDateTime(Map<String, dynamic> data, List<String> keys) {
    final value = _readString(data, keys);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => DioAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(secureTokenStorageProvider),
  ),
);
