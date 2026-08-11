import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/core/api_providers.dart';

/// Wraps the actor-agnostic `notifications/device-tokens` endpoints
/// (`DeviceTokensService` — shared with the customer/admin/restaurant apps,
/// not a rider-specific system).
abstract class DeviceTokenRepository {
  Future<void> register(String token);
  Future<void> remove(String token);
}

class DioDeviceTokenRepository implements DeviceTokenRepository {
  const DioDeviceTokenRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<void> register(String token) async {
    await _apiClient.post<void>(
      ApiEndpoints.deviceTokens,
      data: {'token': token, 'platform': _platform},
    );
  }

  @override
  Future<void> remove(String token) async {
    await _apiClient.delete<void>(
      ApiEndpoints.deviceTokens,
      data: {'token': token},
    );
  }

  String get _platform {
    if (Platform.isIOS) return 'IOS';
    if (Platform.isAndroid) return 'ANDROID';
    return 'WEB';
  }
}

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>(
  (ref) => DioDeviceTokenRepository(apiClient: ref.watch(apiClientProvider)),
);
