import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/core/constants/app_constants.dart';
import 'package:delivery_partner_app/providers/polling/rider_polling_controller.dart';
import 'package:delivery_partner_app/repositories/dashboard/dashboard_repository.dart';
import 'package:delivery_partner_app/repositories/orders/dispatch_repository.dart';
import 'package:delivery_partner_app/repositories/orders/rider_orders_repository.dart';
import 'package:delivery_partner_app/shared/widgets/lifecycle/rider_polling_lifecycle_observer.dart';

import '../../../providers/polling/rider_polling_controller_test.dart'
    show FakeDashboardRepository, FakeDispatchRepository, FakeRiderOrdersRepository;

Widget buildApp({
  required FakeDispatchRepository dispatchRepository,
  FakeRiderOrdersRepository? riderOrdersRepository,
  FakeDashboardRepository? dashboardRepository,
}) {
  return ProviderScope(
    overrides: [
      dispatchRepositoryProvider.overrideWithValue(dispatchRepository),
      riderOrdersRepositoryProvider.overrideWithValue(
          riderOrdersRepository ?? FakeRiderOrdersRepository()),
      dashboardRepositoryProvider.overrideWithValue(
          dashboardRepository ?? FakeDashboardRepository()),
    ],
    child: const MaterialApp(
      home: RiderPollingLifecycleObserver(child: SizedBox.shrink()),
    ),
  );
}

void main() {
  testWidgets(
      'app resume after the controller was started refreshes the dispatch offer regardless of which screen is on top',
      (tester) async {
    final dispatchRepo = FakeDispatchRepository();
    await tester.pumpWidget(buildApp(dispatchRepository: dispatchRepo));
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(RiderPollingLifecycleObserver));
    ProviderScope.containerOf(element)
        .read(riderPollingControllerProvider.notifier)
        .start();
    await tester.pump();

    final before = dispatchRepo.getCurrentOfferCalls;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(dispatchRepo.getCurrentOfferCalls, greaterThan(before));
  });

  testWidgets(
      'app resume before the controller was ever started (rider still on auth/onboarding) does not poll',
      (tester) async {
    final dispatchRepo = FakeDispatchRepository();
    await tester.pumpWidget(buildApp(dispatchRepository: dispatchRepo));
    await tester.pumpAndSettle();

    final before = dispatchRepo.getCurrentOfferCalls;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(dispatchRepo.getCurrentOfferCalls, before);
  });

  testWidgets('app pause stops ticking until the next resume', (tester) async {
    final dispatchRepo = FakeDispatchRepository();
    await tester.pumpWidget(buildApp(dispatchRepository: dispatchRepo));
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(RiderPollingLifecycleObserver));
    ProviderScope.containerOf(element)
        .read(riderPollingControllerProvider.notifier)
        .start();
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final before = dispatchRepo.getCurrentOfferCalls;
    await tester.pump(AppConstants.dispatchOfferPollInterval * 2);

    expect(dispatchRepo.getCurrentOfferCalls, before);
  });
}
