import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _pendingReferralCodeKey = 'pending_referral_code';

  final FlutterSecureStorage _storage;

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
    } catch (_) {}
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (_) {}
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await saveRefreshToken(refreshToken);
    }
  }

  Future<String?> getPendingReferralCode() async {
    try {
      return await _storage.read(key: _pendingReferralCodeKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePendingReferralCode(String code) async {
    try {
      await _storage.write(key: _pendingReferralCodeKey, value: code);
    } catch (_) {}
  }

  Future<void> clearPendingReferralCode() async {
    try {
      await _storage.delete(key: _pendingReferralCodeKey);
    } catch (_) {}
  }

  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
      ]);
    } catch (_) {}
  }
}
