import 'package:flutter/services.dart';
import '../storage/secure_storage.dart';

class ReferralAttributionService {
  ReferralAttributionService(this._storage);
  final SecureTokenStorage _storage;
  static const _channel = MethodChannel('com.qikzoodelivery/referral');

  Future<void> captureLaunchReferral() async {
    try {
      final code = await _channel.invokeMethod<String>('getReferralCode');
      if (code != null && RegExp(r'^[A-Z0-9]{6,24}$').hasMatch(code)) {
        await _storage.savePendingReferralCode(code);
      }
    } catch (_) {}
  }

  Future<String?> pendingCode() => _storage.getPendingReferralCode();
  Future<void> clear() => _storage.clearPendingReferralCode();
}
