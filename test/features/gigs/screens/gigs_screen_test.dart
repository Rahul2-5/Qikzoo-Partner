import 'package:delivery_partner_app/features/gigs/screens/gigs_screen.dart';
import 'package:delivery_partner_app/models/dashboard/dashboard_stats_model.dart';
import 'package:delivery_partner_app/repositories/dashboard/dashboard_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _OfflineDashboardRepository implements DashboardRepository {
  const _OfflineDashboardRepository();

  static const _stats = DashboardStatsModel(
    riderName: 'Ravi Kumar',
    availabilityStatus: RiderAvailabilityStatus.offline,
    todaysEarningsPaise: 0,
    todaysDeliveries: 0,
    walletBalancePaise: 0,
    onlineSecondsToday: 0,
    acceptanceRatePercent: null,
    completionRatePercent: null,
    rating: 0,
    workingZone: null,
  );

  @override
  Future<DashboardStatsModel> getStats() async => _stats;

  @override
  Future<DashboardStatsModel> goOffline() async => _stats;

  @override
  Future<DashboardStatsModel> goOnline() async => _stats;

  @override
  Future<DashboardStatsModel> goAvailable() async => _stats;
}

Widget buildApp() => ProviderScope(
      overrides: [
        dashboardRepositoryProvider
            .overrideWithValue(const _OfflineDashboardRepository()),
      ],
      child: const MaterialApp(home: GigsScreen()),
    );

void main() {
  // GigsScreen is currently a plain StatelessWidget with no dependency on
  // dashboardRepositoryProvider/RiderAvailabilityStatus at all — it never
  // watches any availability state, so there is no "Offline"/"Online" text
  // anywhere in its build() to test. The old "shows Offline when the rider
  // is offline" test covered functionality that doesn't exist in the
  // current implementation; dropped rather than pointed at nonexistent UI.

  testWidgets('shows an honest coming-soon state with no fabricated shift data',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Gigs Scheduling is Coming Soon'), findsOneWidget);
    // Regression guard: the screen previously rendered fabricated mock shift
    // cards ('Breakfast Shift'/'Lunch Shift'/'Dinner Shift' with invented
    // payout ranges) underneath a translucent overlay. That fake data was
    // removed; the coming-soon state must not resurrect it.
    expect(find.text('Breakfast Shift'), findsNothing);
    expect(find.text('Lunch Shift'), findsNothing);
    expect(find.text('Dinner Shift'), findsNothing);
  });

  testWidgets('remains usable on a compact phone', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Gigs Scheduling is Coming Soon'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
