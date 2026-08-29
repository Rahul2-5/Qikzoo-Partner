import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/constants/app_constants.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/core/storage/dispatch_offer_cache.dart';
import 'package:delivery_partner_app/models/dashboard/dashboard_stats_model.dart';
import 'package:delivery_partner_app/models/dashboard/go_online_eligibility_model.dart';
import 'package:delivery_partner_app/models/orders/delivery_completion_model.dart';
import 'package:delivery_partner_app/models/orders/delivery_payment_session.dart';
import 'package:delivery_partner_app/models/orders/dispatch_offer_model.dart';
import 'package:delivery_partner_app/models/orders/order_history_page_model.dart';
import 'package:delivery_partner_app/models/orders/rider_order_model.dart';
import 'package:delivery_partner_app/providers/orders/dispatch_offer_provider.dart';
import 'package:delivery_partner_app/providers/polling/rider_polling_controller.dart';
import 'package:delivery_partner_app/repositories/dashboard/dashboard_repository.dart';
import 'package:delivery_partner_app/repositories/orders/dispatch_repository.dart';
import 'package:delivery_partner_app/repositories/orders/rider_orders_repository.dart';

/// `DispatchOfferNotifier.build()` reads through this store (real impl:
/// `FlutterSecureStorage`, a platform channel unavailable in tests) before
/// ever reaching the already-faked `dispatchRepositoryProvider` — see the
/// equivalent override in incoming_offer_screen_test.dart and
/// dashboard_home_screen_test.dart for the same root cause.
class FakeDispatchOfferStore implements DispatchOfferStore {
  @override
  Future<DispatchOfferModel?> read() async => null;
  @override
  Future<void> write(DispatchOfferModel offer) async {}
  @override
  Future<void> clear() async {}
}

class FakeDispatchRepository implements DispatchRepository {
  FakeDispatchRepository({this.offer});
  DispatchOfferModel? offer;
  int getCurrentOfferCalls = 0;

  @override
  Future<DispatchOfferModel?> getCurrentOffer() async {
    getCurrentOfferCalls++;
    return offer;
  }

  @override
  Future<String> accept(String attemptId) => throw UnimplementedError();

  @override
  Future<void> reject(String attemptId) => throw UnimplementedError();
}

class FakeRiderOrdersRepository implements RiderOrdersRepository {
  FakeRiderOrdersRepository({this.activeOrder});
  RiderOrderModel? activeOrder;
  int getCurrentCalls = 0;

  @override
  Future<List<RiderOrderModel>> getCurrent() async {
    getCurrentCalls++;
    return activeOrder == null ? [] : [activeOrder!];
  }

  @override
  Future<RiderOrderModel> getOne(String riderOrderId) =>
      throw UnimplementedError();

  @override
  Future<OrderHistoryPageModel> getHistory({
    required OrderHistoryFilter filter,
    required int page,
    required int pageSize,
  }) async =>
      OrderHistoryPageModel(items: const [], total: 0, page: page, pageSize: pageSize);

  @override
  Future<void> markArrived(String riderOrderId) => throw UnimplementedError();
  @override
  Future<void> pickupSuccess(String riderOrderId) => throw UnimplementedError();
  @override
  Future<void> scanPickupQr(String riderOrderId, String token) => throw UnimplementedError();
  @override
  Future<void> startDelivery(String riderOrderId) => throw UnimplementedError();
  @override
  Future<DeliveryPaymentSession> createPaymentSession(String riderOrderId) =>
      throw UnimplementedError();
  @override
  Future<DeliveryPaymentSession> getPaymentSession(String riderOrderId) =>
      throw UnimplementedError();
  @override
  Future<void> collectCash(String riderOrderId) => throw UnimplementedError();
  @override
  Future<DeliveryCompletionModel> completeDelivery(String riderOrderId) =>
      throw UnimplementedError();
  @override
  Future<void> cancel(String riderOrderId, String reason) =>
      throw UnimplementedError();
}

class FakeDashboardRepository implements DashboardRepository {
  int getStatsCalls = 0;

  @override
  Future<DashboardStatsModel> getStats() async {
    getStatsCalls++;
    return const DashboardStatsModel(
      riderName: 'Ravi Kumar',
      availabilityStatus: RiderAvailabilityStatus.available,
      todaysEarningsPaise: 0,
      todaysDeliveries: 0,
      walletBalancePaise: 0,
      onlineSecondsToday: 0,
      acceptanceRatePercent: null,
      completionRatePercent: null,
      rating: 5,
      workingZone: null,
    );
  }

  @override
  Future<DashboardStatsModel> goOnline() => getStats();
  @override
  Future<DashboardStatsModel> goAvailable() => getStats();
  @override
  Future<DashboardStatsModel> goOffline() => getStats();
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

ProviderContainer buildContainer({
  FakeDispatchRepository? dispatchRepository,
  FakeRiderOrdersRepository? riderOrdersRepository,
  FakeDashboardRepository? dashboardRepository,
}) {
  final container = ProviderContainer(overrides: [
    dispatchRepositoryProvider
        .overrideWithValue(dispatchRepository ?? FakeDispatchRepository()),
    dispatchOfferStoreProvider.overrideWithValue(FakeDispatchOfferStore()),
    riderOrdersRepositoryProvider.overrideWithValue(
        riderOrdersRepository ?? FakeRiderOrdersRepository()),
    dashboardRepositoryProvider
        .overrideWithValue(dashboardRepository ?? FakeDashboardRepository()),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('start() begins polling both the dispatch offer and the active order',
      (tester) async {
    final dispatchRepo = FakeDispatchRepository();
    final ordersRepo = FakeRiderOrdersRepository();
    final container = buildContainer(
      dispatchRepository: dispatchRepo,
      riderOrdersRepository: ordersRepo,
    );

    container.read(riderPollingControllerProvider.notifier).start();
    // The initial AsyncNotifier.build() fetch, not the poll timer yet.
    await tester.pump();
    final callsAfterStart = dispatchRepo.getCurrentOfferCalls;
    final ordersCallsAfterStart = ordersRepo.getCurrentCalls;

    await tester.pump(AppConstants.dispatchOfferPollInterval);

    expect(dispatchRepo.getCurrentOfferCalls, greaterThan(callsAfterStart));
    expect(ordersRepo.getCurrentCalls, greaterThan(ordersCallsAfterStart));
    container.read(riderPollingControllerProvider.notifier).stop();
  });

  testWidgets('stop() halts further ticks', (tester) async {
    final dispatchRepo = FakeDispatchRepository();
    final container = buildContainer(dispatchRepository: dispatchRepo);

    container.read(riderPollingControllerProvider.notifier).start();
    await tester.pump();
    container.read(riderPollingControllerProvider.notifier).stop();

    final before = dispatchRepo.getCurrentOfferCalls;
    await tester.pump(AppConstants.dispatchOfferPollInterval * 2);

    expect(dispatchRepo.getCurrentOfferCalls, before);
  });

  testWidgets('start() is idempotent — calling it again does not create a second timer',
      (tester) async {
    final dispatchRepo = FakeDispatchRepository();
    final container = buildContainer(dispatchRepository: dispatchRepo);

    final notifier = container.read(riderPollingControllerProvider.notifier);
    notifier.start();
    await tester.pump();
    notifier.start(); // e.g. Dashboard mounted again after a tab switch back
    await tester.pump();

    final before = dispatchRepo.getCurrentOfferCalls;
    await tester.pump(AppConstants.dispatchOfferPollInterval);

    // Exactly one tick's worth of calls, not two overlapping timers' worth.
    expect(dispatchRepo.getCurrentOfferCalls, before + 1);
    notifier.stop();
  });

  testWidgets(
      'handleResume() is a no-op when polling was never started (still on auth/onboarding)',
      (tester) async {
    final dispatchRepo = FakeDispatchRepository();
    final container = buildContainer(dispatchRepository: dispatchRepo);

    final before = dispatchRepo.getCurrentOfferCalls;
    container.read(riderPollingControllerProvider.notifier).handleResume();
    await tester.pump();

    expect(dispatchRepo.getCurrentOfferCalls, before);
  });

  testWidgets(
      'handleResume() after start() immediately refreshes and resumes ticking',
      (tester) async {
    final dispatchRepo = FakeDispatchRepository();
    final dashboardRepo = FakeDashboardRepository();
    final container = buildContainer(
      dispatchRepository: dispatchRepo,
      dashboardRepository: dashboardRepo,
    );

    final notifier = container.read(riderPollingControllerProvider.notifier);
    notifier.start();
    await tester.pump();
    notifier.handlePause();

    final offerCallsBeforeResume = dispatchRepo.getCurrentOfferCalls;
    final statsCallsBeforeResume = dashboardRepo.getStatsCalls;
    notifier.handleResume();
    await tester.pump();

    expect(dispatchRepo.getCurrentOfferCalls, greaterThan(offerCallsBeforeResume));
    expect(dashboardRepo.getStatsCalls, greaterThan(statsCallsBeforeResume));

    // Ticking resumed too, not just the one immediate refresh.
    final afterImmediateRefresh = dispatchRepo.getCurrentOfferCalls;
    await tester.pump(AppConstants.dispatchOfferPollInterval);
    expect(dispatchRepo.getCurrentOfferCalls, greaterThan(afterImmediateRefresh));
    notifier.stop();
  });

  testWidgets('handlePause() stops ticking until handleResume() is called',
      (tester) async {
    final dispatchRepo = FakeDispatchRepository();
    final container = buildContainer(dispatchRepository: dispatchRepo);
    final notifier = container.read(riderPollingControllerProvider.notifier);
    notifier.start();
    await tester.pump();

    notifier.handlePause();
    final before = dispatchRepo.getCurrentOfferCalls;
    await tester.pump(AppConstants.dispatchOfferPollInterval * 2);

    expect(dispatchRepo.getCurrentOfferCalls, before);
  });

  testWidgets(
      'a new dispatch offer detected mid-poll navigates to the incoming offer screen',
      (tester) async {
    final offer = DispatchOfferModel(
      id: 'attempt-1',
      jobId: 'job-1',
      attemptNumber: 1,
      status: DispatchAttemptStatus.waitingRider,
      distanceKm: 2.1,
      searchRadiusKm: 5,
      broadcast: false,
      offeredAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(seconds: 20)),
      payout: 55,
      restaurantName: 'Spice Route Kitchen',
      restaurantAddress: '1 MG Road',
      customerName: 'Test Customer',
      userAddress: '221B Baker Street',
      dropDistanceKm: 3.4,
    );
    final dispatchRepo = FakeDispatchRepository(offer: offer);
    final container = buildContainer(dispatchRepository: dispatchRepo);

    await tester.pumpWidget(GetMaterialApp(
      initialRoute: AppRoutes.dashboard,
      getPages: [
        GetPage(name: AppRoutes.dashboard, page: () => const SizedBox.shrink()),
        GetPage(
          name: AppRoutes.incomingOffer,
          page: () => const Text('Incoming Offer Screen'),
        ),
      ],
    ));

    final notifier = container.read(riderPollingControllerProvider.notifier);
    notifier.start();
    await tester.pumpAndSettle();

    expect(find.text('Incoming Offer Screen'), findsOneWidget);
    notifier.stop();
  });
}
