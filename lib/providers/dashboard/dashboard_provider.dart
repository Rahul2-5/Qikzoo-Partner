import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/dashboard/dashboard_repository.dart';
import '../../models/dashboard/dashboard_stats_model.dart';
import '../../models/dashboard/go_online_eligibility_model.dart';

class DashboardStatsNotifier extends AsyncNotifier<DashboardStatsModel> {
  int _refreshVersion = 0;

  @override
  Future<DashboardStatsModel> build() =>
      ref.watch(dashboardRepositoryProvider).getStats();

  Future<void> refresh() async {
    final refreshVersion = ++_refreshVersion;
    // Keep the last successful snapshot rendered while a background refresh
    // runs. Acceptance, completion, polling, and resume can all refresh this
    // provider around the same navigation transition; replacing data with
    // AsyncLoading here caused the dashboard to briefly disappear.
    final refreshed = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).getStats(),
    );
    if (refreshVersion == _refreshVersion) state = refreshed;
  }

  Future<GoOnlineEligibilityModel> checkOnlineEligibility() =>
      ref.read(dashboardRepositoryProvider).getOnlineEligibility();

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
  Future<void> goAvailable() async {
    final updated = await ref.read(dashboardRepositoryProvider).goAvailable();
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
