import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/orders/screens/incoming_offer_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/orders/delivery_completion_model.dart';
import 'package:delivery_partner_app/models/orders/delivery_payment_session.dart';
import 'package:delivery_partner_app/models/orders/dispatch_offer_model.dart';
import 'package:delivery_partner_app/models/orders/order_history_page_model.dart';
import 'package:delivery_partner_app/models/orders/rider_order_model.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/orders/dispatch_repository.dart';
import 'package:delivery_partner_app/repositories/orders/rider_orders_repository.dart';
import 'package:delivery_partner_app/core/storage/dispatch_offer_cache.dart';
import 'package:delivery_partner_app/providers/orders/dispatch_offer_provider.dart';

/// `DispatchOfferNotifier.build()` reads through this store before hitting
/// the network (see dispatch_offer_provider.dart). The real implementation
/// talks to `FlutterSecureStorage`, a platform channel unavailable in widget
/// tests; overriding it here keeps offer-loading deterministic instead of
/// depending on the MissingPluginException fallback timing.
class _FakeDispatchOfferStore implements DispatchOfferStore {
  @override
  Future<DispatchOfferModel?> read() async => null;
  @override
  Future<void> write(DispatchOfferModel offer) async {}
  @override
  Future<void> clear() async {}
}

class FakeDispatchRepository implements DispatchRepository {
  FakeDispatchRepository({this.initial});
  DispatchOfferModel? initial;
  DispatchOfferModel? current;
  Object? acceptError;
  Object? rejectError;
  int acceptCalls = 0;
  int rejectCalls = 0;
  String? lastAcceptedId;
  String? lastRejectedId;

  @override
  Future<DispatchOfferModel?> getCurrentOffer() async => current ??= initial;

  @override
  Future<String> accept(String attemptId) async {
    acceptCalls++;
    lastAcceptedId = attemptId;
    if (acceptError != null) throw acceptError!;
    return 'rider-order-1';
  }

  @override
  Future<void> reject(String attemptId) async {
    rejectCalls++;
    lastRejectedId = attemptId;
    if (rejectError != null) throw rejectError!;
  }
}

/// Backs activeOrderProvider.loadAcceptedOrder(riderOrderId), which the
/// screen now calls right after a successful accept() (see
/// incoming_offer_screen.dart) — without an override here, that call would
/// hit the real Dio-based repository and its real network client.
class FakeRiderOrdersRepository implements RiderOrdersRepository {
  RiderOrderModel? order = mockAcceptedOrder();

  @override
  Future<RiderOrderModel> getOne(String riderOrderId) async {
    if (order == null) throw StateError('No order to return.');
    return order!;
  }

  @override
  Future<List<RiderOrderModel>> getCurrent() => throw UnimplementedError();
  @override
  Future<OrderHistoryPageModel> getHistory({
    required OrderHistoryFilter filter,
    required int page,
    required int pageSize,
  }) =>
      throw UnimplementedError();
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
  Future<void> cancel(String riderOrderId, String reason) => throw UnimplementedError();
}

RiderOrderModel mockAcceptedOrder() => RiderOrderModel(
      id: 'rider-order-1',
      orderId: 'order-1',
      status: RiderOrderStatus.accepted,
      distanceKm: 3.2,
      earningsPaise: 0,
      tipsPaise: 0,
      etaMinutes: 12,
      assignedAt: DateTime(2026, 7, 23, 10),
      acceptedAt: DateTime(2026, 7, 23, 10, 1),
      arrivedAt: null,
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
      order: const RestaurantOrderSummary(
        id: 'order-1',
        orderNumber: 'BR-1',
        customerName: 'Asha Rao',
        customerPhone: null,
        deliveryAddressLine: '221B Baker Street',
        deliveryCity: 'Bengaluru',
        deliveryPincode: '560001',
        deliveryLat: 12.99,
        deliveryLng: 77.61,
        totalPaise: 45000,
        customerNote: null,
        status: RestaurantOrderStatus.handedToRider,
        statusHistory: null,
        pickupOtp: null,
        paymentMethod: OrderPaymentMethod.cod,
        paymentStatus: OrderPaymentStatus.pending,
        paidAt: null,
        paymentReference: null,
        collectionSource: null,
      ),
    );

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

DispatchOfferModel mockOffer({
  String id = 'attempt-1',
  bool broadcast = false,
  Duration remaining = const Duration(seconds: 20),
  double distanceKm = 2.5,
}) =>
    DispatchOfferModel(
      id: id,
      jobId: 'job-1',
      attemptNumber: 1,
      status: DispatchAttemptStatus.waitingRider,
      distanceKm: distanceKm,
      searchRadiusKm: 5,
      broadcast: broadcast,
      offeredAt: DateTime.now(),
      expiresAt: DateTime.now().add(remaining),
      payout: 50,
      restaurantName: 'Test Restaurant',
      restaurantAddress: '1 Test Street',
      customerName: 'Test Customer',
      userAddress: '2 Test Avenue',
      dropDistanceKm: 3.0,
    );

Widget buildApp({
  required DispatchRepository dispatchRepository,
  FakeAuthRepository? authRepository,
  // Production only ever reaches IncomingOfferScreen via Get.toNamed on top
  // of the dashboard (see RiderPollingController._openRouteOnce and
  // PushService), so `Get.back()` inside the screen's reject flow always has
  // a real previous route to pop to. Defaulting the test harness to
  // incomingOffer as the root route (no history) made Get.back() a no-op,
  // leaving the screen's poll Timer.periodic running forever and hanging
  // pumpAndSettle. Tests that exercise the reject/back flow set this true.
  bool withDashboardBackstack = false,
}) {
  return ProviderScope(
    overrides: [
      dispatchRepositoryProvider.overrideWithValue(dispatchRepository),
      dispatchOfferStoreProvider.overrideWithValue(_FakeDispatchOfferStore()),
      riderOrdersRepositoryProvider.overrideWithValue(FakeRiderOrdersRepository()),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
    ],
    child: GetMaterialApp(
      initialRoute:
          withDashboardBackstack ? AppRoutes.dashboard : AppRoutes.incomingOffer,
      getPages: [
        if (withDashboardBackstack)
          GetPage(
            name: AppRoutes.dashboard,
            page: () => const Scaffold(body: Text('Dashboard Screen')),
          ),
        GetPage(
            name: AppRoutes.incomingOffer, page: () => const IncomingOfferScreen()),
        GetPage(
          name: AppRoutes.activeOrder,
          page: () => const Scaffold(body: Text('Active Order Screen')),
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

  testWidgets('shows the offer distance, countdown, and accept/reject actions',
      (tester) async {
    final repo = FakeDispatchRepository(initial: mockOffer());
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();
    await tester.pump();

    // Header copy: "New Order" / "You have received a new order"
    // (incoming_offer_screen.dart _OfferView header Row).
    expect(find.text('New Order'), findsOneWidget);
    expect(find.text('Test Restaurant'), findsOneWidget);
    expect(find.textContaining('₹50'), findsOneWidget);
    expect(find.text('1 Test Street'), findsOneWidget);
    expect(find.text('2 Test Avenue'), findsOneWidget);
    // Action buttons were relabelled "Decline" / "Accept Order".
    expect(find.text('Accept Order'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.textContaining('00:'), findsOneWidget);
  });

  // NOTE: the screen was redesigned to the current card layout (see the
  // "matching screenshot style" comments in incoming_offer_screen.dart) and
  // no longer renders any broadcast/"offered to several riders" indicator —
  // `offer.broadcast` is parsed from the API but unused in the widget tree.
  // This is a confirmed, intentional UI simplification, not a regression,
  // so the obsolete assertion for that removed indicator has been dropped
  // rather than kept pointed at nonexistent UI.

  testWidgets('accepting navigates to the active order screen', (tester) async {
    final repo = FakeDispatchRepository(initial: mockOffer());
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Accept Order'));
    await tester.pumpAndSettle();

    expect(repo.acceptCalls, 1);
    expect(repo.lastAcceptedId, 'attempt-1');
    expect(find.text('Active Order Screen'), findsOneWidget);
  });

  testWidgets('rejecting returns to the previous screen', (tester) async {
    final repo = FakeDispatchRepository(initial: mockOffer());
    await tester.pumpWidget(
      buildApp(dispatchRepository: repo, withDashboardBackstack: true),
    );
    await tester.pump();
    Get.toNamed(AppRoutes.incomingOffer);
    await tester.pump();
    await tester.pump();

    expect(find.text('New Order'), findsOneWidget);

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();

    expect(repo.rejectCalls, 1);
    expect(find.text('New Order'), findsNothing);
    expect(find.text('Dashboard Screen'), findsOneWidget);
  });

  testWidgets('does not double-submit accept on rapid duplicate taps', (tester) async {
    final repo = FakeDispatchRepository(initial: mockOffer());
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Accept Order'));
    await tester.tap(find.text('Accept Order'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(repo.acceptCalls, 1);
  });

  testWidgets('a failed accept shows an error and keeps the offer visible', (tester) async {
    final repo = FakeDispatchRepository(initial: mockOffer())
      ..acceptError = const ApiException(message: 'This offer is no longer available.');
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Accept Order'));
    await tester.pumpAndSettle();

    expect(find.textContaining('This offer is no longer available'), findsOneWidget);
    expect(find.text('New Order'), findsOneWidget);
  });

  testWidgets('a 401 on accept logs the rider out and navigates to welcome', (tester) async {
    final repo = FakeDispatchRepository(initial: mockOffer())
      ..acceptError = const ApiException(message: 'Unauthorized', statusCode: 401);
    final authRepo = FakeAuthRepository();
    await tester
        .pumpWidget(buildApp(dispatchRepository: repo, authRepository: authRepo));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Accept Order'));
    await tester.pumpAndSettle();

    expect(authRepo.loggedOut, isTrue);
    expect(find.text('Welcome Screen'), findsOneWidget);
  });

  testWidgets('an already-expired offer shows the "no longer available" state immediately',
      (tester) async {
    final repo = FakeDispatchRepository(
      initial: mockOffer(remaining: const Duration(seconds: -5)),
    );
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();
    await tester.pump();

    // offer.isExpired routes to the same _NoOrderView as a null offer
    // (incoming_offer_screen.dart: `if (offer == null || offer.isExpired)`).
    expect(find.text('This order is no longer available.'), findsOneWidget);
    expect(find.text('Accept Order'), findsNothing);
  });

  testWidgets('no offer at all shows the "no longer available" state', (tester) async {
    final repo = FakeDispatchRepository(initial: null);
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();
    await tester.pump();

    expect(find.text('This order is no longer available.'), findsOneWidget);
  });

  testWidgets('a load failure shows Retry, which succeeds on retry', (tester) async {
    final repo = FakeDispatchRepository()..current = null;
    // Force the initial build to fail by throwing from getCurrentOffer once.
    var callCount = 0;
    final failingRepo = _ThrowOnceThenSucceed(repo, () => callCount++ == 0);
    await tester.pumpWidget(buildApp(dispatchRepository: failingRepo));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Unable to connect'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('This order is no longer available.'), findsOneWidget);
  });
}

class _ThrowOnceThenSucceed implements DispatchRepository {
  _ThrowOnceThenSucceed(this._delegate, this._shouldThrow);
  final DispatchRepository _delegate;
  final bool Function() _shouldThrow;

  @override
  Future<DispatchOfferModel?> getCurrentOffer() async {
    if (_shouldThrow()) {
      throw const ApiException(message: 'Unable to connect. Check your internet connection.');
    }
    return _delegate.getCurrentOffer();
  }

  @override
  Future<String> accept(String attemptId) => _delegate.accept(attemptId);

  @override
  Future<void> reject(String attemptId) => _delegate.reject(attemptId);
}
