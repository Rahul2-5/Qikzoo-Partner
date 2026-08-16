import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/location/rider_location_ping.dart';
import '../../providers/core/api_providers.dart';

/// Wraps `POST /rider/location` (`RiderLocationController`/
/// `UpdateRiderLocationDto`) — the single existing endpoint the backend
/// already exposes for live position pings. No new endpoint, no new
/// backend model: the same one `RiderLocationService.updateLocation()`
/// writes into `Rider.lastLat/lastLng/lastLocationAt`, the `RiderLocation`
/// history table, and (only while the rider's availability status is
/// AVAILABLE) the `riders:geo` Redis GEO set dispatch searches.
abstract class LocationRepository {
  Future<void> sendPing(RiderLocationPing ping);
}

class DioLocationRepository implements LocationRepository {
  const DioLocationRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<void> sendPing(RiderLocationPing ping) async {
    await _apiClient.post<void>(
      ApiEndpoints.riderLocation,
      data: ping.toJson(),
    );
  }
}

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => DioLocationRepository(apiClient: ref.watch(apiClientProvider)),
);
