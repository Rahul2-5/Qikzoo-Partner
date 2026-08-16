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
import 'package:delivery_partner_app/shared/widgets/buttons/primary_cta_button.dart';

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
  int completeDeliveryCalls = 0;
  int cancelCalls = 0;
  int getCurrentCalls = 0;
  String? lastCancelReason;

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
  Future<void> completeDelivery(String riderOrderId) async {
    completeDeliveryCalls++;
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

  RiderOrderModel _withStatus(RiderOrderStatus status, {DateTime? arrivedAt}) => RiderOrderModel(
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
        pickedUpAt: order!.pickedUpAt,
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
    expect(find.text('221B Baker Street'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Mark arrived at restaurant'), findsOneWidget);
  });

  testWidgets(
      'only the restaurant call button renders while customerPhone is redacted (null)',
      (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder(customerPhone: null));
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    // Restaurant always has a phone; the customer's only appears once the
    // backend actually returns it (hasArrivedAtRestaurant gate).
    expect(find.byIcon(LucideIcons.phone), findsOneWidget);
  });

  testWidgets('the customer call button appears once the backend exposes their phone',
      (tester) async {
    final repo = FakeRiderOrdersRepository(
      order: mockOrder(
        status: RiderOrderStatus.arrivedAtRestaurant,
        customerPhone: '9998887777',
      ),
    );
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.phone), findsNWidgets(2));
  });

  testWidgets(
      'tapping "Mark arrived" calls markArrived and shows the read-only pickup OTP panel '
      'with no primary action button', (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder());
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark arrived at restaurant'));
    // Not pumpAndSettle from here: markArrived sets arrivedAt, which mounts
    // _WaitingTicker's own Timer.periodic — a periodic timer never lets
    // pumpAndSettle observe "no more scheduled frames", so bounded pumps
    // drive the same frames instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repo.markArrivedCalls, 1);
    expect(find.text('At restaurant'), findsOneWidget);
    expect(find.text('Pickup OTP'), findsOneWidget);
    expect(
      find.text('Tell this OTP to the restaurant staff to collect the order.'),
      findsOneWidget,
    );
    // No primary action button while ARRIVED_AT_RESTAURANT — the rider is
    // only waiting, never typing/scanning/confirming anything themselves.
    expect(find.text('Mark arrived at restaurant'), findsNothing);
    expect(find.text('Start delivery'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);

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

    expect(find.text('4829'), findsOneWidget);
    expect(find.textContaining('Waiting for restaurant'), findsOneWidget);

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
    expect(find.text('4829'), findsOneWidget);

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
    expect(find.text('Pickup OTP'), findsNothing);
    expect(find.text('Picked up'), findsOneWidget);
    expect(find.text('Start delivery'), findsOneWidget);
  });

  testWidgets('tapping "Start delivery" advances to out-for-delivery', (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder(status: RiderOrderStatus.pickedUp));
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start delivery'));
    await tester.pumpAndSettle();

    expect(repo.startDeliveryCalls, 1);
    expect(find.text('Out for delivery'), findsOneWidget);
    // The new DeliveryHandoffCard section (shown only for outForDelivery)
    // pushes this button below the initial viewport in the list — it's
    // still built (within the sliver's cache extent) but skipOffstage's
    // default excludes it, so it must be searched for explicitly here.
    expect(
      find.text('Mark delivered', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets(
      "shows 'not at the delivery location' copy with a distance and disables Mark "
      'delivered while the rider is still far away', (tester) async {
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

    final button = tester.widget<PrimaryCtaButton>(
      find.widgetWithText(PrimaryCtaButton, 'Mark delivered', skipOffstage: false),
    );
    expect(button.onPressed, isNull);
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

    final button = tester.widget<PrimaryCtaButton>(
      find.widgetWithText(PrimaryCtaButton, 'Mark delivered', skipOffstage: false),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
      'disables Mark delivered and shows a waiting-for-location message when there is no '
      'GPS fix yet', (tester) async {
    final repo =
        FakeRiderOrdersRepository(order: mockOrder(status: RiderOrderStatus.outForDelivery));

    await tester.pumpWidget(
      buildApp(repository: repo, locationState: RiderLocationTrackingState.idle),
    );
    await tester.pumpAndSettle();

    expect(find.text('Waiting for your location…', skipOffstage: false), findsOneWidget);

    final button = tester.widget<PrimaryCtaButton>(
      find.widgetWithText(PrimaryCtaButton, 'Mark delivered', skipOffstage: false),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
      'tapping the enabled Mark delivered button calls completeDelivery with just the '
      'riderOrderId (no code)', (tester) async {
    final repo =
        FakeRiderOrdersRepository(order: mockOrder(status: RiderOrderStatus.outForDelivery));

    await tester.pumpWidget(
      buildApp(repository: repo, locationState: nearDeliveryLocationState),
    );
    await tester.pumpAndSettle();

    // DeliveryHandoffCard + the proximity panel (shown for outForDelivery)
    // push this button below the initial viewport — scroll it into view
    // first, since a tap at an off-screen coordinate silently misses the
    // real hit target.
    final markDeliveredFinder = find.text('Mark delivered', skipOffstage: false);
    await tester.ensureVisible(markDeliveredFinder);
    await tester.pump();
    await tester.tap(markDeliveredFinder);
    await tester.pumpAndSettle();

    expect(repo.completeDeliveryCalls, 1);
    expect(find.text('No active order right now.'), findsOneWidget);
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

    final markDeliveredFinder = find.text('Mark delivered', skipOffstage: false);
    await tester.ensureVisible(markDeliveredFinder);
    await tester.pump();
    await tester.tap(markDeliveredFinder);
    await tester.pumpAndSettle();

    expect(repo.completeDeliveryCalls, 1);
    expect(find.text('You are too far from the delivery location.'), findsOneWidget);
    // The order stays visible and OUT_FOR_DELIVERY — the rider can retry
    // once they've actually moved closer, never a silent success.
    expect(find.text('Out for delivery', skipOffstage: false), findsOneWidget);
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

    final markDeliveredFinder = find.text('Mark delivered', skipOffstage: false);
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

    expect(find.text('Cancel order'), findsOneWidget);
    await tester.tap(find.text('Cancel order'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField), 'Vehicle breakdown');
    await tester.pump();
    await tester.tap(find.text('Cancel order').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repo.cancelCalls, 1);
    expect(repo.lastCancelReason, 'Vehicle breakdown');
    expect(find.text('No active order right now.'), findsOneWidget);
  });

  testWidgets(
      'cancelling refreshes the order-history lists so a stale Ongoing/Cancelled entry cannot linger',
      (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder());
    await tester.pumpWidget(buildApp(repository: repo, watchOrderHistory: true));
    await tester.pumpAndSettle();
    final callsBeforeCancel =
        repo.historyCalls[OrderHistoryFilter.cancelled] ?? 0;

    await tester.tap(find.text('Cancel order'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'Vehicle breakdown');
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

    await tester.tap(find.text('Mark arrived at restaurant'));
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

    await tester.tap(find.text('Mark arrived at restaurant'));
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
