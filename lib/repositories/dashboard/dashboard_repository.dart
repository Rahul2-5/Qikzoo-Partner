import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../../models/dashboard/dashboard_stats_model.dart';
import '../../providers/core/api_providers.dart';

abstract class DashboardRepository {
  /// Combines `GET /rider/profile` + `GET /rider/earnings/summary` +
  /// `GET /rider/wallet` into a single dashboard-ready snapshot.
  Future<DashboardStatsModel> getStats();

  /// `POST /rider/availability/online`, then re-fetches the full snapshot
  /// so earnings/wallet/rates stay consistent with the new status rather
  /// than being merged in manually.
  Future<DashboardStatsModel> goOnline();

  /// `POST /rider/availability/offline` — see [goOnline].
  Future<DashboardStatsModel> goOffline();
}

class MockDashboardRepository implements DashboardRepository {
  RiderAvailabilityStatus _status = RiderAvailabilityStatus.offline;

  @override
  Future<DashboardStatsModel> getStats() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return DashboardStatsModel(
      riderName: 'Ravi Kumar',
      availabilityStatus: _status,
      todaysEarningsPaise: 84200,
      todaysDeliveries: 14,
      walletBalancePaise: 312000,
      acceptanceRatePercent: 92,
      completionRatePercent: 96,
      rating: 4.7,
      workingZone: 'Bengaluru, Karnataka',
    );
  }

  @override
  Future<DashboardStatsModel> goOnline() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    _status = RiderAvailabilityStatus.online;
    return getStats();
  }

  @override
  Future<DashboardStatsModel> goOffline() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    _status = RiderAvailabilityStatus.offline;
    return getStats();
  }
}

class DioDashboardRepository implements DashboardRepository {
  const DioDashboardRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<DashboardStatsModel> getStats() async {
    final results = await Future.wait([
      _apiClient.get<Map<String, dynamic>>(ApiEndpoints.riderProfile),
      _apiClient.get<Map<String, dynamic>>(ApiEndpoints.riderEarningsSummary),
      _apiClient.get<Map<String, dynamic>>(ApiEndpoints.riderWallet),
    ]);

    final profile = _unwrap(results[0].data);
    final earnings = _unwrap(results[1].data);
    final wallet = _unwrap(results[2].data);
    final today = _asMap(earnings['today']);

    final totalOffers = _asInt(profile['totalOffers']);
    final totalAccepted = _asInt(profile['totalAccepted']);
    final totalOrdersCancelled = _asInt(profile['totalOrdersCancelled']);

    final city = _asString(profile['city']);
    final state = _asString(profile['state']);
    final workingZone = [city, state].where((v) => v != null && v.isNotEmpty).join(', ');

    return DashboardStatsModel(
      riderName: _asString(profile['name']) ?? '',
      availabilityStatus:
          RiderAvailabilityStatus.fromBackend(_asString(profile['availabilityStatus'])),
      todaysEarningsPaise: _asInt(today['earningsPaise']),
      todaysDeliveries: _asInt(today['deliveries']),
      walletBalancePaise: _asInt(wallet['availableBalancePaise']),
      acceptanceRatePercent:
          totalOffers > 0 ? (totalAccepted / totalOffers) * 100 : null,
      completionRatePercent: totalAccepted > 0
          ? ((totalAccepted - totalOrdersCancelled) / totalAccepted) * 100
          : null,
      rating: _asDouble(profile['rating']) ?? 5.0,
      workingZone: workingZone.isEmpty ? null : workingZone,
    );
  }

  @override
  Future<DashboardStatsModel> goOnline() async {
    await _apiClient.post<void>(ApiEndpoints.riderAvailabilityOnline);
    return getStats();
  }

  @override
  Future<DashboardStatsModel> goOffline() async {
    await _apiClient.post<void>(ApiEndpoints.riderAvailabilityOffline);
    return getStats();
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    final nested = body?['data'];
    final payload = nested is Map<String, dynamic> ? nested : body;
    return payload ?? const {};
  }

  Map<String, dynamic> _asMap(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  String? _asString(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return null;
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DioDashboardRepository(apiClient: ref.watch(apiClientProvider)),
);
