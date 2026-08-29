import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/orders/screens/active_order_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/orders/order_history_page_model.dart';
import 'package:delivery_partner_app/models/orders/rider_order_model.dart';
import 'package:delivery_partner_app/providers/location/rider_location_provider.dart';
import 'package:delivery_partner_app/providers/location/rider_location_state.dart';
import 'package:delivery_partner_app/providers/orders/order_history_provider.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/orders/rider_orders_repository.dart';

/// Fixes `riderLocationControllerProvider`'s state to whatever a test wants
/// without driving the real permission/GPS-fix flow (that's already covered
/// by dashboard_home_screen_test.dart) — this screen only ever reads the
/// controller's current state, never starts/stops tracking itself.
class FixedRiderLocationController extends RiderLocationController {
  FixedRiderLocationController(this._state);
  final RiderLocationTrackingState _state;

  @override
  RiderLocationTrackingState build() => _state;
}

class FakeRiderOrdersRepository implements RiderOrdersRepository {
  FakeRiderOrdersRepository({required this.order});
  RiderOrderModel? order;
  Object? actionError;

  int markArrivedCalls = 0;
  int startDeliveryCalls = 0;
  int pickupSuccessCalls = 0;
  int completeDeliveryCalls = 0;
  int cancelCalls = 0;
  int getCurrentCalls = 0;
  String? lastCancelReason;
  String? lastCompleteDeliveryCode;

  @override
  Future<List<RiderOrderModel>> getCurrent() async {
    getCurrentCalls++;
    return order == null ? [] : [order!];
  }

  @override
  Future<RiderOrderModel> getOne(String riderOrderId) async {
    if (actionError != null) throw actionError!;
    return order!;
  }

  final Map<OrderHistoryFilter, int> historyCalls = {};

  @override
  Future<OrderHistoryPageModel> getHistory({
    required OrderHistoryFilter filter,
    required int page,
    required int pageSize,
  }) async {
    historyCalls.update(filter, (v) => v + 1, ifAbsent: () => 1);
    return OrderHistoryPageModel(items: const [], total: 0, page: page, pageSize: pageSize);
  }

  @override
  Future<void> markArrived(String riderOrderId) async {
    markArrivedCalls++;
    if (actionError != null) throw actionError!;
    order = _withStatus(RiderOrderStatus.arrivedAtRestaurant, arrivedAt: DateTime.now());
  }

  @override
  Future<void> startDelivery(String riderOrderId) async {
    startDeliveryCalls++;
    if (actionError != null) throw actionError!;
    order = _withStatus(RiderOrderStatus.outForDelivery);
  }

  @override
  Future<void> pickupSuccess(String riderOrderId) async {
    pickupSuccessCalls++;
    if (actionError != null) throw actionError!;
    order = _withStatus(RiderOrderStatus.pickedUp, pickedUpAt: DateTime.now());
  }

  @override
  Future<void> scanPickupQr(String riderOrderId, String token) async {
    if (actionError != null) throw actionError!;
    order = _withStatus(RiderOrderStatus.pickedUp, pickedUpAt: DateTime.now());
  }

  @override
  Future<void> completeDelivery(String riderOrderId, String code) async {
    completeDeliveryCalls++;
    lastCompleteDeliveryCode = code;
    if (actionError != null) throw actionError!;
    order = null;
  }

  @override
  Future<void> cancel(String riderOrderId, String reason) async {
    cancelCalls++;
    lastCancelReason = reason;
    if (actionError != null) throw actionError!;
    order = null;
  }

  RiderOrderModel _withStatus(
    RiderOrderStatus status, {
    DateTime? arrivedAt,
    DateTime? pickedUpAt,
  }) =>
      RiderOrderModel(
        id: order!.id,
        orderId: order!.orderId,
        status: status,
        distanceKm: order!.distanceKm,
        earningsPaise: order!.earningsPaise,
        tipsPaise: order!.tipsPaise,
        etaMinutes: order!.etaMinutes,
        assignedAt: order!.assignedAt,
        acceptedAt: order!.acceptedAt,
        arrivedAt: arrivedAt ?? order!.arrivedAt,
        pickedUpAt: pickedUpAt ?? order!.pickedUpAt,
        outForDeliveryAt: order!.outForDeliveryAt,
        deliveredAt: order!.deliveredAt,
        cancelledAt: order!.cancelledAt,
        cancellationReason: order!.cancellationReason,
        restaurant: order!.restaurant,
        order: order!.order,
      );
}

class FakeAuthRepository implements AuthRepository {
  bool loggedOut = false;

  @override
  Future<OtpModel> requestOtp(String phoneNumber) => throw UnimplementedError();

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp, {String? name}) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {
    loggedOut = true;
  }
}

RiderOrderModel mockOrder({
  RiderOrderStatus status = RiderOrderStatus.accepted,
  String? customerPhone,
  DateTime? arrivedAt,
  PickupOtpInfo? pickupOtp,
  double? deliveryLat = 12.99,
  double? deliveryLng = 77.61,
}) =>
    RiderOrderModel(
      id: 'rider-order-1',
      orderId: 'order-1',
      status: status,
      distanceKm: 3.2,
      earningsPaise: 0,
      tipsPaise: 0,
      etaMinutes: 12,
      assignedAt: DateTime(2026, 7, 23, 10),
      acceptedAt: DateTime(2026, 7, 23, 10, 1),
      arrivedAt: arrivedAt,
      pickedUpAt: null,
      outForDeliveryAt: null,
      deliveredAt: null,
      cancelledAt: null,
      cancellationReason: null,
      restaurant: const RestaurantContactModel(
        name: 'Spice Route Kitchen',
        phone: '9000000001',
        address: '1 MG Road',
        landmark: 'Near Metro',
        latitude: 12.97,
        longitude: 77.59,
      ),
      order: RestaurantOrderSummary(
        id: 'order-1',
        orderNumber: 'BR-1',
        customerName: 'Asha Rao',
        customerPhone: customerPhone,
        deliveryAddressLine: '221B Baker Street',
        deliveryCity: 'Bengaluru',
        deliveryPincode: '560001',
        deliveryLat: deliveryLat,
        deliveryLng: deliveryLng,
        totalPaise: 45000,
        customerNote: null,
        status: RestaurantOrderStatus.handedToRider,
        statusHistory: null,
        pickupOtp: pickupOtp,
      ),
    );

/// Exactly at [mockOrder]'s default delivery coordinates — a live position
/// here means zero distance, i.e. "at the delivery location".
const nearDeliveryLocationState = RiderLocationTrackingState(
  status: RiderLocationTrackingStatus.active,
  lastLat: 12.99,
  lastLng: 77.61,
);

/// [mockOrder]'s restaurant coordinates — well outside the 150m UX
/// threshold from its default delivery coordinates.
const farFromDeliveryLocationState = RiderLocationTrackingState(
  status: RiderLocationTrackingStatus.active,
  lastLat: 12.97,
  lastLng: 77.59,
);

Widget buildApp({
  required FakeRiderOrdersRepository repository,
  FakeAuthRepository? authRepository,
  /// When true, mounts an off-screen watcher of orderHistoryProvider so a
  /// test can observe ActiveOrderScreen's ref.invalidate(...) calls
  /// actually triggering a refetch — a provider that nobody is watching
  /// would just be marked dirty without any observable getHistory call.
  bool watchOrderHistory = false,
  /// Defaults to "near" so existing tests that don't care about the
  /// delivery-proximity gate (they exercise earlier statuses) don't have to
  /// think about it; only the OUT_FOR_DELIVERY-specific tests below vary it.
  RiderLocationTrackingState locationState = nearDeliveryLocationState,
}) {
  return ProviderScope(
    overrides: [
      riderOrdersRepositoryProvider.overrideWithValue(repository),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
      riderLocationControllerProvider
          .overrideWith(() => FixedRiderLocationController(locationState)),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.activeOrder,
      getPages: [
        GetPage(
          name: AppRoutes.activeOrder,
          page: () => Stack(
            children: [
              const ActiveOrderScreen(),
              if (watchOrderHistory)
                Consumer(
                  builder: (context, ref, _) {
                    ref.watch(orderHistoryProvider(OrderHistoryFilter.completed));
                    ref.watch(orderHistoryProvider(OrderHistoryFilter.cancelled));
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
        ),
        GetPage(
          name: AppRoutes.welcome,
          page: () => const Scaffold(body: Text('Welcome Screen')),
        ),
        // ActiveOrderScreen auto-navigates here (Get.offAllNamed) once the
        // active order disappears (e.g. right after a successful delivery
        // completion) — see its ref.listen block.
        GetPage(
          name: AppRoutes.orders,
          page: () => const Scaffold(body: Text('Orders Screen')),
        ),
      ],
    ),
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('shows restaurant/customer contact and status for an accepted order',
      (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder());
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Spice Route Kitchen'), findsOneWidget);
    // The customer's delivery address is only shown once the order is
    // PICKED_UP/OUT_FOR_DELIVERY — for an ACCEPTED order the rider is still
    // heading to the restaurant, so only the pickup ("Pickup from") contact
    // is on screen yet.
    expect(find.text('1 MG Road'), findsOneWidget);
    expect(find.text('221B Baker Street'), findsNothing);
    // The screen's journey snapshot shows a task-oriented label for this
    // stage, not the raw RiderOrderStatus.label ("Accepted") — see
    // _journeySnapshot.
    expect(find.text('Navigate to pickup'), findsOneWidget);
    expect(find.text("I've Arrived"), findsOneWidget);
  });

  testWidgets(
      'only the restaurant call button renders while customerPhone is redacted (null)',
      (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder(customerPhone: null));
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    // Restaurant always has a phone; the customer's only appears once the
    // backend actually returns it (hasArrivedAtRestaurant gate).
    expect(find.byIcon(LucideIcons.phoneCall), findsOneWidget);
  });

  testWidgets('the customer call button appears once the order is picked up',
      (tester) async {
    // The "Deliver to" ContactCard (and its call button) only renders from
    // PICKED_UP onward — see active_order_screen.dart's status gate — not
    // merely once customerPhone is non-null. The "Pickup from" restaurant
    // ContactCard is gated the other way (accepted/arrivedAtRestaurant
    // only), so by PICKED_UP it's gone and only the customer's call button
    // remains — not both.
    final repo = FakeRiderOrdersRepository(
      order: mockOrder(
        status: RiderOrderStatus.pickedUp,
        customerPhone: '9998887777',
      ),
    );
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.phoneCall, skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'tapping "I\'ve Arrived" calls markArrived and shows the read-only pickup OTP panel '
      'alongside the manual Picked Up confirmation', (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder());
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text("I've Arrived"));
    // Not pumpAndSettle from here: markArrived sets arrivedAt, which mounts
    // _WaitingTicker's own Timer.periodic — a periodic timer never lets
    // pumpAndSettle observe "no more scheduled frames", so bounded pumps
    // drive the same frames instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repo.markArrivedCalls, 1);
    expect(find.text('Arrived at restaurant'), findsOneWidget);
    // The OTP panel is further down the ListView, past the initial
    // viewport/cache extent.
    expect(find.text('Pickup Verification OTP', skipOffstage: false), findsOneWidget);
    expect(
      find.text(
        'Show this OTP to restaurant staff. They will enter it on their terminal to verify and hand over the order.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    // The rider now also has a manual "Picked Up" confirmation button
    // alongside the passive OTP panel (see _verifyAndConfirmPickup) — no
    // longer "wait only". The old "I've Arrived" prompt is gone either way.
    expect(find.text("I've Arrived"), findsNothing);
    expect(find.text('Picked Up'), findsOneWidget);
    expect(find.text('Start Delivery'), findsNothing);

    await tester.tap(find.text('Picked Up'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(repo.pickupSuccessCalls, 1);

    // Unmount so the ticker's Timer.periodic is cancelled in dispose()
    // before the test completes (a still-pending periodic timer would
    // otherwise fail the test).
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows the restaurant-verified pickup OTP code once present', (tester) async {
    final repo = FakeRiderOrdersRepository(
      order: mockOrder(
        status: RiderOrderStatus.arrivedAtRestaurant,
        arrivedAt: DateTime.now(),
        pickupOtp: PickupOtpInfo(
          code: '4829',
          status: PickupOtpStatus.active,
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        ),
      ),
    );
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Each OTP digit renders in its own boxed Text (_PickupVerificationCard
    // builds one Container per character), not as a single "4829" string.
    for (final digit in ['4', '8', '2', '9']) {
      expect(find.text(digit, skipOffstage: false), findsOneWidget);
    }
    expect(find.textContaining('Waiting for restaurant', skipOffstage: false), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'the pickup OTP panel disappears once the backend moves the order to PICKED_UP '
      '(the restaurant verifying the OTP on their own dashboard, observed via polling)',
      (tester) async {
    final repo = FakeRiderOrdersRepository(
      order: mockOrder(
        status: RiderOrderStatus.arrivedAtRestaurant,
        arrivedAt: DateTime.now(),
        pickupOtp: PickupOtpInfo(
          code: '4829',
          status: PickupOtpStatus.active,
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        ),
      ),
    );
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    for (final digit in ['4', '8', '2', '9']) {
      expect(find.text(digit, skipOffstage: false), findsOneWidget);
    }

    // The rider never calls anything to advance past ARRIVED_AT_RESTAURANT
    // — restaurant staff verify the OTP on their own dashboard and the
    // backend flips RiderOrder straight to PICKED_UP. This app only ever
    // observes that via a refetch; pull-to-refresh stands in here for the
    // app's existing poll timer.
    repo.order = mockOrder(status: RiderOrderStatus.pickedUp);
    final refreshIndicator =
        tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await refreshIndicator.onRefresh();
    await tester.pumpAndSettle();

    expect(find.text('4829'), findsNothing);
    expect(find.text('Pickup Verification OTP'), findsNothing);
    expect(find.text('Pickup confirmed'), findsOneWidget);
    expect(find.text('Start Delivery', skipOffstage: false), findsOneWidget);
  });

  testWidgets('tapping "Start Delivery" advances to out-for-delivery', (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder(status: RiderOrderStatus.pickedUp));
    // buildApp() defaults to a "near" location (so earlier-status tests
    // that don't care about proximity don't have to think about it), but
    // this test checks the "not yet arrived" journey label, so it needs
    // the far location explicitly — otherwise _journeySnapshot's
    // `outForDelivery when arrivedAtCustomer` branch wins and the label is
    // "Arrived at customer" instead of "On the way".
    await tester.pumpWidget(
      buildApp(repository: repo, locationState: farFromDeliveryLocationState),
    );
    await tester.pumpAndSettle();

    final startDeliveryFinder = find.text('Start Delivery', skipOffstage: false);
    await tester.ensureVisible(startDeliveryFinder);
    await tester.pump();
    await tester.tap(startDeliveryFinder);
    await tester.pumpAndSettle();

    expect(repo.startDeliveryCalls, 1);
    // Journey-snapshot label for OUT_FOR_DELIVERY (not yet arrived at the
    // customer) — see _journeySnapshot — not the raw status label.
    expect(find.text('On the way'), findsOneWidget);
    // The new DeliveryHandoffCard section (shown only for outForDelivery)
    // pushes this button below the initial viewport in the list — it's
    // still built (within the sliver's cache extent) but skipOffstage's
    // default excludes it, so it must be searched for explicitly here.
    expect(
      find.text('Delivered', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets(
      "shows 'not at the delivery location' copy with a distance, but still lets the rider "
      'tap Delivered (the backend is the real proximity gate, not the client)', (tester) async {
    // See the `_deliveryProximityThresholdMeters` doc comment: it's a
    // "client-side-only UX threshold for the ... button/copy" — the backend
    // independently enforces its own real radius server-side, and rejects a
    // too-far completion with an error (see the dedicated rejection test
    // below) rather than the client pre-emptively disabling the button.
    final repo =
        FakeRiderOrdersRepository(order: mockOrder(status: RiderOrderStatus.outForDelivery));
    final farDistance = Geolocator.distanceBetween(
        farFromDeliveryLocationState.lastLat!, farFromDeliveryLocationState.lastLng!, 12.99, 77.61);
    final expectedDistanceLabel = farDistance < 1000
        ? '${farDistance.round()} m away'
        : '${(farDistance / 1000).toStringAsFixed(1)} km away';

    await tester.pumpWidget(
      buildApp(repository: repo, locationState: farFromDeliveryLocationState),
    );
    await tester.pumpAndSettle();

    expect(find.text("You're not at the delivery location yet", skipOffstage: false),
        findsOneWidget);
    expect(find.text(expectedDistanceLabel, skipOffstage: false), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Delivered', skipOffstage: false),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
      "shows 'at the delivery location' copy and enables Mark delivered once the rider's "
      'live position is within range', (tester) async {
    final repo =
        FakeRiderOrdersRepository(order: mockOrder(status: RiderOrderStatus.outForDelivery));

    await tester.pumpWidget(
      buildApp(repository: repo, locationState: nearDeliveryLocationState),
    );
    await tester.pumpAndSettle();

    expect(
      find.text("You're at the delivery location", skipOffstage: false),
      findsOneWidget,
    );

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Delivered', skipOffstage: false),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
      'shows a waiting-for-location message when there is no GPS fix yet, but still lets the '
      'rider tap Delivered', (tester) async {
    final repo =
        FakeRiderOrdersRepository(order: mockOrder(status: RiderOrderStatus.outForDelivery));

    await tester.pumpWidget(
      buildApp(repository: repo, locationState: RiderLocationTrackingState.idle),
    );
    await tester.pumpAndSettle();

    expect(find.text('Waiting for your location...', skipOffstage: false), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Delivered', skipOffstage: false),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
      'entering the 6-digit delivery OTP and tapping Mark delivered calls completeDelivery '
      'with the riderOrderId and that code', (tester) async {
    final repo =
        FakeRiderOrdersRepository(order: mockOrder(status: RiderOrderStatus.outForDelivery));

    await tester.pumpWidget(
      buildApp(repository: repo, locationState: nearDeliveryLocationState),
    );
    await tester.pumpAndSettle();

    // DeliveryHandoffCard + the proximity panel (shown for outForDelivery)
    // push both the OTP field and the button below the initial
    // viewport/cache extent — scroll each into view first, since a tap or
    // enterText at an off-screen/not-yet-built target silently misses.
    final otpFieldFinder = find.byType(TextField, skipOffstage: false);
    await tester.ensureVisible(otpFieldFinder);
    await tester.pump();
    await tester.enterText(otpFieldFinder, '123456');
    await tester.pump();
    final markDeliveredFinder = find.text('Delivered', skipOffstage: false);
    await tester.ensureVisible(markDeliveredFinder);
    await tester.pump();
    await tester.tap(markDeliveredFinder);
    await tester.pumpAndSettle();

    expect(repo.completeDeliveryCalls, 1);
    expect(repo.lastCompleteDeliveryCode, '123456');
    // Once the order disappears (completed), the screen auto-navigates
    // away to the orders list rather than showing its own empty state in
    // place — see the ref.listen block in active_order_screen.dart.
    expect(find.text('Orders Screen'), findsOneWidget);
  });

  testWidgets(
      'tapping Mark delivered without entering the OTP shows an error and never calls completeDelivery',
      (tester) async {
    final repo =
        FakeRiderOrdersRepository(order: mockOrder(status: RiderOrderStatus.outForDelivery));

    await tester.pumpWidget(
      buildApp(repository: repo, locationState: nearDeliveryLocationState),
    );
    await tester.pumpAndSettle();

    final markDeliveredFinder = find.text('Delivered', skipOffstage: false);
    await tester.ensureVisible(markDeliveredFinder);
    await tester.pump();
    await tester.tap(markDeliveredFinder);
    await tester.pumpAndSettle();

    expect(repo.completeDeliveryCalls, 0);
    expect(find.text('Enter the 6-digit delivery OTP.'), findsOneWidget);
  });

  testWidgets(
      'the server rejecting completion (e.g. too far) shows an error rather than silently '
      'succeeding', (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder(status: RiderOrderStatus.outForDelivery))
      ..actionError = const ApiException(message: 'You are too far from the delivery location.');

    await tester.pumpWidget(
      buildApp(repository: repo, locationState: nearDeliveryLocationState),
    );
    await tester.pumpAndSettle();

    final otpFieldFinder = find.byType(TextField, skipOffstage: false);
    await tester.ensureVisible(otpFieldFinder);
    await tester.pump();
    await tester.enterText(otpFieldFinder, '123456');
    await tester.pump();
    final markDeliveredFinder = find.text('Delivered', skipOffstage: false);
    await tester.ensureVisible(markDeliveredFinder);
    await tester.pump();
    await tester.tap(markDeliveredFinder);
    await tester.pumpAndSettle();

    expect(repo.completeDeliveryCalls, 1);
    expect(find.text('You are too far from the delivery location.'), findsOneWidget);
    // The order stays visible and OUT_FOR_DELIVERY — the rider can retry
    // once they've actually moved closer, never a silent success. Journey
    // snapshot label at this (near) location + outForDelivery status is
    // "Arrived at customer", not the raw status label.
    expect(find.text('Arrived at customer', skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'completing delivery refreshes the order-history lists so a stale Ongoing/Completed entry cannot linger',
      (tester) async {
    final repo =
        FakeRiderOrdersRepository(order: mockOrder(status: RiderOrderStatus.outForDelivery));
    await tester.pumpWidget(buildApp(
      repository: repo,
      watchOrderHistory: true,
      locationState: nearDeliveryLocationState,
    ));
    await tester.pumpAndSettle();
    final callsBeforeComplete =
        repo.historyCalls[OrderHistoryFilter.completed] ?? 0;

    final otpFieldFinder = find.byType(TextField, skipOffstage: false);
    await tester.ensureVisible(otpFieldFinder);
    await tester.pump();
    await tester.enterText(otpFieldFinder, '123456');
    await tester.pump();
    final markDeliveredFinder = find.text('Delivered', skipOffstage: false);
    await tester.ensureVisible(markDeliveredFinder);
    await tester.pump();
    await tester.tap(markDeliveredFinder);
    await tester.pumpAndSettle();

    expect(
      repo.historyCalls[OrderHistoryFilter.completed] ?? 0,
      greaterThan(callsBeforeComplete),
    );
  });

  testWidgets('cancel is offered for a non-terminal order and submits a reason',
      (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder());
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    final cancelFinder = find.text('Cancel order', skipOffstage: false);
    expect(cancelFinder, findsOneWidget);
    await tester.ensureVisible(cancelFinder);
    await tester.pump();
    await tester.tap(cancelFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // CancelOrderSheet now offers a fixed list of reasons (radio-style
    // tiles) instead of a freeform text field — the sheet's own "Cancel
    // order" button stays disabled until one is selected.
    await tester.tap(find.text('Vehicle issue'));
    await tester.pump();
    await tester.tap(find.text('Cancel order').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repo.cancelCalls, 1);
    expect(repo.lastCancelReason, 'Vehicle issue');
    // Cancelling auto-navigates away to the orders list, same as a
    // completed delivery — see _cancel's Get.offAllNamed(AppRoutes.orders).
    expect(find.text('Orders Screen'), findsOneWidget);
  });

  testWidgets(
      'cancelling refreshes the order-history lists so a stale Ongoing/Cancelled entry cannot linger',
      (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder());
    await tester.pumpWidget(buildApp(repository: repo, watchOrderHistory: true));
    await tester.pumpAndSettle();
    final callsBeforeCancel =
        repo.historyCalls[OrderHistoryFilter.cancelled] ?? 0;

    final cancelFinder = find.text('Cancel order', skipOffstage: false);
    await tester.ensureVisible(cancelFinder);
    await tester.pump();
    await tester.tap(cancelFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Vehicle issue'));
    await tester.pump();
    await tester.tap(find.text('Cancel order').last);
    await tester.pumpAndSettle();

    expect(
      repo.historyCalls[OrderHistoryFilter.cancelled] ?? 0,
      greaterThan(callsBeforeCancel),
    );
  });

  testWidgets('a failed action shows a snackbar and keeps the order visible',
      (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder())
      ..actionError = const ApiException(message: 'Something went wrong upstream.');
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text("I've Arrived"));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong upstream.'), findsOneWidget);
    expect(find.text('Spice Route Kitchen'), findsOneWidget);
  });

  testWidgets('a 401 on an action logs the rider out and navigates to welcome',
      (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder())
      ..actionError = const ApiException(message: 'Unauthorized', statusCode: 401);
    final authRepo = FakeAuthRepository();
    await tester.pumpWidget(buildApp(repository: repo, authRepository: authRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text("I've Arrived"));
    await tester.pumpAndSettle();

    expect(authRepo.loggedOut, isTrue);
    expect(find.text('Welcome Screen'), findsOneWidget);
  });

  testWidgets('pull-to-refresh reloads the active order', (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder());
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    final before = repo.getCurrentCalls;
    final refreshIndicator =
        tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await refreshIndicator.onRefresh();
    await tester.pumpAndSettle();

    expect(repo.getCurrentCalls, greaterThan(before));
  });

  testWidgets('no active order shows the empty state', (tester) async {
    final repo = FakeRiderOrdersRepository(order: null);
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('No active order right now.'), findsOneWidget);
  });

  // This screen no longer owns its own poll timer/lifecycle observer —
  // activeOrderProvider is kept fresh by RiderPollingController for the
  // whole authenticated session (see its doc comment), so resume-triggered
  // refresh is covered by test/providers/polling/rider_polling_controller_test.dart
  // and test/shared/widgets/lifecycle/rider_polling_lifecycle_observer_test.dart
  // instead of here.
}
