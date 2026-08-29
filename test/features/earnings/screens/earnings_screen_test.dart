import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/earnings/screens/earnings_screen.dart';
import 'package:delivery_partner_app/models/dashboard/dashboard_stats_model.dart';
import 'package:delivery_partner_app/models/dashboard/go_online_eligibility_model.dart';
import 'package:delivery_partner_app/models/earnings/earnings_models.dart';
import 'package:delivery_partner_app/repositories/dashboard/dashboard_repository.dart';
import 'package:delivery_partner_app/repositories/earnings/earnings_repository.dart';

class FakeEarningsRepository implements EarningsRepository {
  FakeEarningsRepository({EarningsSummaryModel? summary, EarningsHistoryPage? history})
      : _summary = summary ?? EarningsSummaryModel.empty,
        _history = history ?? EarningsHistoryPage.empty;

  final EarningsSummaryModel _summary;
  final EarningsHistoryPage _history;

  @override
  Future<EarningsSummaryModel> getSummary() async => _summary;

  @override
  Future<EarningsHistoryPage> getHistory({int page = 1, int pageSize = 20}) async => _history;
}

class FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardStatsModel> getStats() async => const DashboardStatsModel(
        riderName: 'Test Rider',
        availabilityStatus: RiderAvailabilityStatus.online,
        todaysEarningsPaise: 0,
        todaysDeliveries: 0,
        walletBalancePaise: 0,
        onlineSecondsToday: 0,
        acceptanceRatePercent: null,
        completionRatePercent: null,
        rating: 5,
        workingZone: null,
      );

  @override
  Future<DashboardStatsModel> goOffline() => getStats();

  @override
  Future<DashboardStatsModel> goOnline() => getStats();

  @override
  Future<DashboardStatsModel> goAvailable() => getStats();

  @override
  Future<GoOnlineEligibilityModel> getOnlineEligibility() async =>
      const GoOnlineEligibilityModel(
        eligible: true,
        blockers: [],
        selfieRequired: false,
        selfieMissing: false,
        livenessRequired: false,
      );
}

Widget buildApp({
  required EarningsRepository earningsRepository,
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    ProviderScope(
      overrides: [
        earningsRepositoryProvider.overrideWithValue(earningsRepository),
        dashboardRepositoryProvider.overrideWithValue(FakeDashboardRepository()),
      ],
      child: GetMaterialApp(
        initialRoute: AppRoutes.earnings,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child ?? const SizedBox.shrink(),
        ),
        getPages: [
          GetPage(name: AppRoutes.earnings, page: () => const EarningsScreen()),
          GetPage(
              name: AppRoutes.dashboard,
              page: () => const Scaffold(body: Text('Dashboard Screen'))),
          GetPage(
              name: AppRoutes.payoutsDetail,
              page: () => const Scaffold(body: Text('Payouts Detail Screen'))),
          GetPage(
              name: AppRoutes.earningsHistoryDetail,
              page: () =>
                  const Scaffold(body: Text('Earnings History Detail Screen'))),
        ],
      ),
    );

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('shows the weekly earnings total, delivery count, and tips',
      (tester) async {
    // EarningsScreen was redesigned to a single "This week" hero total (see
    // _WeeklyEarningsCard, which reads only `summary.thisWeek` — the
    // `today`/`lifetime` buckets are still fetched but no longer surfaced
    // anywhere in this screen's UI) — the old Today/This Week/Lifetime
    // period-switcher this file used to test does not exist any more.
    final repo = FakeEarningsRepository(
      summary: const EarningsSummaryModel(
        today: EarningsBucket.zero,
        thisWeek: EarningsBucket(deliveries: 3, earningsPaise: 45000, tipsPaise: 5000),
        lifetime: EarningsBucket.zero,
      ),
    );
    await tester.pumpWidget(buildApp(earningsRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('This week'), findsOneWidget);
    // CurrencyFormatter.rupees shows whole rupees, no decimals.
    expect(find.textContaining('₹500'), findsOneWidget);
    expect(find.text('3 deliveries'), findsOneWidget);
    expect(find.text('₹50 tips'), findsOneWidget);
  });

  testWidgets('Payouts & balance navigates to the payouts detail route',
      (tester) async {
    final repo = FakeEarningsRepository();
    await tester.pumpWidget(buildApp(earningsRepository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Payouts & balance'));
    await tester.pumpAndSettle();

    expect(find.text('Payouts Detail Screen'), findsOneWidget);
  });

  testWidgets('View all navigates to the earnings history detail route',
      (tester) async {
    final repo = FakeEarningsRepository();
    await tester.pumpWidget(buildApp(earningsRepository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();

    expect(find.text('Earnings History Detail Screen'), findsOneWidget);
  });

  testWidgets('shows a real delivery history entry with its order number',
      (tester) async {
    final repo = FakeEarningsRepository(
      history: EarningsHistoryPage(
        items: [
          EarningsHistoryEntry(
            id: 'ro-1',
            orderNumber: 'BR-42',
            earningsPaise: 4000,
            tipsPaise: 500,
            deliveredAt: DateTime(2026, 8, 1, 10),
          ),
        ],
        total: 1,
        page: 1,
        pageSize: 20,
      ),
    );
    await tester.pumpWidget(buildApp(earningsRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('BR-42'), findsOneWidget);
    expect(find.textContaining('₹45'), findsOneWidget);
  });

  testWidgets('shows an honest empty state when there is no delivery history',
      (tester) async {
    final repo = FakeEarningsRepository();
    await tester.pumpWidget(buildApp(earningsRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('No deliveries yet'), findsOneWidget);
  });

  testWidgets('remains usable on compact screens with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildApp(
        earningsRepository: FakeEarningsRepository(),
        textScaler: const TextScaler.linear(1.5),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This week'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
