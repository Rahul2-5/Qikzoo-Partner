import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/orders/screens/order_details_screen.dart';
import 'package:delivery_partner_app/models/orders/order_history_page_model.dart';
import 'package:delivery_partner_app/models/orders/rider_order_model.dart';
import 'package:delivery_partner_app/repositories/orders/rider_orders_repository.dart';

class FakeRiderOrdersRepository implements RiderOrdersRepository {
  FakeRiderOrdersRepository({required this.order});
  RiderOrderModel? order;
  Object? getOneError;
  int getOneCalls = 0;

  @override
  Future<RiderOrderModel> getOne(String riderOrderId) async {
    getOneCalls++;
    if (getOneError != null) throw getOneError!;
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
  Future<void> scanPickupQr(String riderOrderId, String token) => throw UnimplementedError();
  @override
  Future<void> pickupSuccess(String riderOrderId) => throw UnimplementedError();
  @override
  Future<void> startDelivery(String riderOrderId) => throw UnimplementedError();
  @override
  Future<void> completeDelivery(String riderOrderId, String code) =>
      throw UnimplementedError();
  @override
  Future<void> cancel(String riderOrderId, String reason) => throw UnimplementedError();
}

RiderOrderModel mockDeliveredOrder({
  List<OrderStatusHistoryEntry>? statusHistory,
  RiderOrderStatus status = RiderOrderStatus.delivered,
  String? cancellationReason,
}) =>
    RiderOrderModel(
      id: 'rider-order-1',
      orderId: 'order-1',
      status: status,
      distanceKm: 3.4,
      earningsPaise: 4500,
      tipsPaise: 500,
      etaMinutes: null,
      assignedAt: DateTime(2026, 7, 23, 10),
      acceptedAt: DateTime(2026, 7, 23, 10, 1),
      arrivedAt: DateTime(2026, 7, 23, 10, 10),
      pickedUpAt: DateTime(2026, 7, 23, 10, 15),
      outForDeliveryAt: DateTime(2026, 7, 23, 10, 16),
      deliveredAt: DateTime(2026, 7, 23, 10, 30),
      cancelledAt: null,
      cancellationReason: cancellationReason,
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
        customerPhone: '9999999999',
        deliveryAddressLine: '221B Baker Street',
        deliveryCity: 'Bengaluru',
        deliveryPincode: '560001',
        deliveryLat: 12.99,
        deliveryLng: 77.61,
        totalPaise: 45000,
        customerNote: null,
        status: RestaurantOrderStatus.delivered,
        statusHistory: statusHistory,
      ),
      pickupQr: null,
      deliveryOtp: null,
    );

Widget buildApp({required FakeRiderOrdersRepository repository, String id = 'rider-order-1'}) {
  return ProviderScope(
    overrides: [riderOrdersRepositoryProvider.overrideWithValue(repository)],
    child: GetMaterialApp(
      initialRoute: AppRoutes.orderDetails,
      getPages: [
        GetPage(
          name: AppRoutes.orderDetails,
          page: () => OrderDetailsScreen(riderOrderId: id),
        ),
      ],
    ),
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('shows restaurant, customer, and earnings for a delivered order',
      (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockDeliveredOrder());
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Order #BR-1'), findsOneWidget);
    expect(find.text('Spice Route Kitchen'), findsOneWidget);
    expect(find.text('221B Baker Street'), findsOneWidget);
    expect(find.textContaining('45'), findsWidgets);
    expect(find.textContaining('5'), findsWidgets); // tip
  });

  testWidgets('shows the full status timeline from the detail response', (tester) async {
    final repo = FakeRiderOrdersRepository(
      order: mockDeliveredOrder(statusHistory: [
        OrderStatusHistoryEntry(
          fromStatus: RestaurantOrderStatus.newOrder,
          toStatus: RestaurantOrderStatus.accepted,
          reason: null,
          changedAt: DateTime(2026, 7, 23, 9),
        ),
        OrderStatusHistoryEntry(
          fromStatus: RestaurantOrderStatus.accepted,
          toStatus: RestaurantOrderStatus.delivered,
          reason: null,
          changedAt: DateTime(2026, 7, 23, 10, 30),
        ),
      ]),
    );
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Order timeline'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Delivered'), findsWidgets);
  });

  testWidgets('shows the cancellation reason for a cancelled order', (tester) async {
    final repo = FakeRiderOrdersRepository(
      order: mockDeliveredOrder(
        status: RiderOrderStatus.cancelled,
        cancellationReason: 'Vehicle breakdown',
      ),
    );
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Cancellation reason'), findsOneWidget);
    expect(find.text('Vehicle breakdown'), findsOneWidget);
  });

  testWidgets('does not show earnings amount for a non-delivered order', (tester) async {
    final repo =
        FakeRiderOrdersRepository(order: mockDeliveredOrder(status: RiderOrderStatus.cancelled));
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('₹45'), findsNothing);
  });

  testWidgets('a load failure shows Retry, which succeeds on retry', (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockDeliveredOrder())
      ..getOneError = const ApiException(message: 'Unable to connect. Check your internet connection.');
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('Unable to connect'), findsOneWidget);

    repo.getOneError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Order #BR-1'), findsOneWidget);
  });

  testWidgets('pull-to-refresh reloads the order detail', (tester) async {
    final repo = FakeRiderOrdersRepository(order: mockDeliveredOrder());
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    final before = repo.getOneCalls;
    final refreshIndicator =
        tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await refreshIndicator.onRefresh();
    await tester.pumpAndSettle();

    expect(repo.getOneCalls, greaterThan(before));
  });
}
