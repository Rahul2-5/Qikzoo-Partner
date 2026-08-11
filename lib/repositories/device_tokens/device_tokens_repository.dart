import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/core/api_providers.dart';

abstract class DeviceTokensRepository {
  Future<void> register(String token, String platform);
  Future<void> remove(String token);
}

class DioDeviceTokensRepository implements DeviceTokensRepository {
  const DioDeviceTokensRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<void> register(String token, String platform) async {
    await _apiClient.post<void>(
      ApiEndpoints.riderDeviceTokens,
      data: {'token': token, 'platform': platform},
    );
  }

  @override
  Future<void> remove(String token) async {
    await _apiClient.delete<void>(
      ApiEndpoints.riderDeviceTokens,
      data: {'token': token},
    );
  }
}

final deviceTokensRepositoryProvider = Provider<DeviceTokensRepository>(
  (ref) => DioDeviceTokensRepository(apiClient: ref.watch(apiClientProvider)),
);
