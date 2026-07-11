import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/dashboard/dashboard_stats_model.dart';

abstract class DashboardRepository {
  Future<DashboardStatsModel> getStats();
  Future<DashboardStatsModel> setOnline(bool isOnline);
}

class MockDashboardRepository implements DashboardRepository {
  bool _isOnline = false;

  @override
  Future<DashboardStatsModel> getStats() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return DashboardStatsModel(
      isOnline: _isOnline,
      todaysEarnings: 842,
      walletBalance: 3120,
      activeIncentives: 2,
      acceptanceRate: 0.92,
      rating: 4.7,
      completedOrders: 14,
    );
  }

  @override
  Future<DashboardStatsModel> setOnline(bool isOnline) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    _isOnline = isOnline;
    return getStats();
  }
}

final dashboardRepositoryProvider =
    Provider<DashboardRepository>((ref) => MockDashboardRepository());
