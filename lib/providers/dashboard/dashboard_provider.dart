import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/dashboard/dashboard_repository.dart';
import '../../models/dashboard/dashboard_stats_model.dart';

class DashboardStatsNotifier extends AsyncNotifier<DashboardStatsModel> {
  @override
  Future<DashboardStatsModel> build() =>
      ref.watch(dashboardRepositoryProvider).getStats();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).getStats(),
    );
  }

  /// Deliberately does NOT go through [AsyncValue.guard]: a failed toggle
  /// (offline, a 400 on an invalid backend transition, a 401) must not
  /// blow away already-loaded good stats with a full-screen error state —
  /// the exception propagates to the caller, which shows a snackbar and
  /// leaves the last known-good [state] exactly as it was.
  Future<void> goOnline() async {
    final updated = await ref.read(dashboardRepositoryProvider).goOnline();
    state = AsyncData(updated);
  }

  /// See [goOnline].
  Future<void> goOffline() async {
    final updated = await ref.read(dashboardRepositoryProvider).goOffline();
    state = AsyncData(updated);
  }
}

final dashboardStatsProvider =
    AsyncNotifierProvider<DashboardStatsNotifier, DashboardStatsModel>(
  DashboardStatsNotifier.new,
);
