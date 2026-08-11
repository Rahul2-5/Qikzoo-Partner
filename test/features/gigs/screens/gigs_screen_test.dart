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
}

Widget buildApp() => ProviderScope(
      overrides: [
        dashboardRepositoryProvider
            .overrideWithValue(const _OfflineDashboardRepository()),
      ],
      child: const MaterialApp(home: GigsScreen()),
    );

void main() {
  testWidgets('shows Offline when the rider is offline', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets(
      'shows an honest coming-soon state instead of fabricated gig bookings',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Gig scheduling is coming soon'), findsOneWidget);
    expect(find.text('Weekend Boost'), findsNothing);
    expect(find.text('Extra Earnings'), findsNothing);
  });

  testWidgets('remains usable on a compact phone', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Gig scheduling is coming soon'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
