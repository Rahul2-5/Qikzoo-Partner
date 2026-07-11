import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/dashboard/dashboard_repository.dart';
import '../../models/dashboard/dashboard_stats_model.dart';

class DashboardStatsNotifier extends AsyncNotifier<DashboardStatsModel> {
  @override
  Future<DashboardStatsModel> build() => ref.watch(dashboardRepositoryProvider).getStats();

  Future<void> toggleOnline(bool isOnline) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).setOnline(isOnline),
    );
  }
}

final dashboardStatsProvider = AsyncNotifierProvider<DashboardStatsNotifier, DashboardStatsModel>(
  DashboardStatsNotifier.new,
);
