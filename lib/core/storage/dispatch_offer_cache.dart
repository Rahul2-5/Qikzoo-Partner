import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/orders/dispatch_offer_model.dart';

abstract interface class DispatchOfferStore {
  Future<DispatchOfferModel?> read();
  Future<void> write(DispatchOfferModel offer);
  Future<void> clear();
}

/// A best-effort UI snapshot of the last pending offer.
///
/// The server remains authoritative. This cache only prevents a blank/loading
/// gap after process death and preserves the server's absolute expiry time.
class DispatchOfferCache implements DispatchOfferStore {
  DispatchOfferCache({FlutterSecureStorage? storage})
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

  static const _key = 'pending_dispatch_offer_v1';
  final FlutterSecureStorage _storage;

  @override
  Future<DispatchOfferModel?> read() async {
    try {
      final encoded = await _storage.read(key: _key);
      if (encoded == null || encoded.isEmpty) return null;
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) return null;
      final offer = DispatchOfferModel.fromJson(decoded);
      if (offer.id.isEmpty || offer.isExpired) {
        await clear();
        return null;
      }
      return offer;
    } catch (_) {
      // Storage can be unavailable in tests or before platform startup. The
      // network path below still restores the authoritative offer.
      return null;
    }
  }

  @override
  Future<void> write(DispatchOfferModel offer) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(offer.toJson()));
    } catch (_) {
      // Cache failures must never block an offer from being shown or accepted.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Best effort only.
    }
  }
}
