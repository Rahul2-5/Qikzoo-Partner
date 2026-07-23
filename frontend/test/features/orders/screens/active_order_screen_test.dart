import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/orders/screens/active_order_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/orders/order_history_page_model.dart';
import 'package:delivery_partner_app/models/orders/rider_order_model.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/orders/rider_orders_repository.dart';

class FakeRiderOrdersRepository implements RiderOrdersRepository {
  FakeRiderOrdersRepository({required this.order});
  RiderOrderModel? order;
  Object? actionError;

  int markArrivedCalls = 0;
  int scanPickupQrCalls = 0;
  int pickupSuccessCalls = 0;
  int startDeliveryCalls = 0;
  int completeDeliveryCalls = 0;
  int cancelCalls = 0;
  int getCurrentCalls = 0;
  String? lastOtpCode;
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

  @override
  Future<OrderHistoryPageModel> getHistory({
    required OrderHistoryFilter filter,
    required int page,
    required int pageSize,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> markArrived(String riderOrderId) async {
    markArrivedCalls++;
    if (actionError != null) throw actionError!;
    order = _withStatus(RiderOrderStatus.arrivedAtRestaurant);
  }

  @override
  Future<void> scanPickupQr(String riderOrderId, String token) async {
    scanPickupQrCalls++;
    if (actionError != null) throw actionError!;
  }

  @override
  Future<void> pickupSuccess(String riderOrderId) async {
    pickupSuccessCalls++;
    if (actionError != null) throw actionError!;
    order = _withStatus(RiderOrderStatus.pickedUp);
  }

  @override
  Future<void> startDelivery(String riderOrderId) async {
    startDeliveryCalls++;
    if (actionError != null) throw actionError!;
    order = _withStatus(RiderOrderStatus.outForDelivery);
  }

  @override
  Future<void> completeDelivery(String riderOrderId, String code) async {
    completeDeliveryCalls++;
    lastOtpCode = code;
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

  RiderOrderModel _withStatus(RiderOrderStatus status) => RiderOrderModel(
        id: order!.id,
        orderId: order!.orderId,
        status: status,
        distanceKm: order!.distanceKm,
        earningsPaise: order!.earningsPaise,
        tipsPaise: order!.tipsPaise,
        etaMinutes: order!.etaMinutes,
        assignedAt: order!.assignedAt,
        acceptedAt: order!.acceptedAt,
        arrivedAt: order!.arrivedAt,
        pickedUpAt: order!.pickedUpAt,
        outForDeliveryAt: order!.outForDeliveryAt,
        deliveredAt: order!.deliveredAt,
        cancelledAt: order!.cancelledAt,
        cancellationReason: order!.cancellationReason,
        restaurant: order!.restaurant,
        order: order!.order,
        pickupQr: order!.pickupQr,
        deliveryOtp: order!.deliveryOtp,
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
  PickupQrInfo? pickupQr,
  DeliveryOtpInfo? deliveryOtp,
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
      order: RestaurantOrderSummary(
        id: 'order-1',
        orderNumber: 'BR-1',
        customerName: 'Asha Rao',
        customerPhone: customerPhone,
        deliveryAddressLine: '221B Baker Street',
        deliveryCity: 'Bengaluru',
        deliveryPincode: '560001',
        deliveryLat: 12.99,
        deliveryLng: 77.61,
        totalPaise: 45000,
        customerNote: null,
        status: RestaurantOrderStatus.handedToRider,
        statusHistory: null,
      ),
      pickupQr: pickupQr,
      deliveryOtp: deliveryOtp,
    );

Widget buildApp({
  required FakeRiderOrdersRepository repository,
  FakeAuthRepository? authRepository,
}) {
  return ProviderScope(
    overrides: [
      riderOrdersRepositoryProvider.overrideWithValue(repository),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.activeOrder,
      getPages: [
        GetPage(name: AppRoutes.activeOrder, page: () => const ActiveOrderScreen()),
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

  testWidgets('tapping "Mark arrived" calls markArrived and refreshes to the next stage',
      (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder());
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark arrived at restaurant'));
    await tester.pumpAndSettle();

    expect(repo.markArrivedCalls, 1);
    expect(find.text('At restaurant'), findsOneWidget);
    expect(find.text('Scan pickup QR'), findsOneWidget);
  });

  testWidgets('shows "Confirm pickup" once the pickup QR has been scanned', (tester) async {
    final repo = FakeRiderOrdersRepository(
      order: mockOrder(
        status: RiderOrderStatus.arrivedAtRestaurant,
        pickupQr: PickupQrInfo(
          status: PickupQrStatus.used,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      ),
    );
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Confirm pickup'), findsOneWidget);
    expect(find.text('Scan pickup QR'), findsNothing);

    await tester.tap(find.text('Confirm pickup'));
    await tester.pumpAndSettle();

    expect(repo.pickupSuccessCalls, 1);
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
    expect(find.text('Complete delivery'), findsOneWidget);
  });

  testWidgets(
      'completing delivery opens the OTP sheet and submits the entered code',
      (tester) async {
    final repo = FakeRiderOrdersRepository(
      order: mockOrder(
        status: RiderOrderStatus.outForDelivery,
        deliveryOtp: DeliveryOtpInfo(
          status: DeliveryOtpStatus.active,
          attempts: 0,
          maxAttempts: 5,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
        ),
      ),
    );
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    // pumpAndSettle isn't used from here on: OtpField's underlying
    // PinCodeTextField runs a repeating cursor animation once the sheet is
    // shown, which never settles — bounded pumps drive the same frames
    // without waiting indefinitely.
    await tester.tap(find.text('Complete delivery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Enter delivery OTP'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '654321');
    await tester.pump();
    await tester.tap(find.text('Confirm delivery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repo.completeDeliveryCalls, 1);
    expect(repo.lastOtpCode, '654321');
    expect(find.text('No active order right now.'), findsOneWidget);
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

  testWidgets('resuming the app after being backgrounded refreshes the order',
      (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockOrder());
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    final before = repo.getCurrentCalls;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(repo.getCurrentCalls, greaterThan(before));
  });
}
