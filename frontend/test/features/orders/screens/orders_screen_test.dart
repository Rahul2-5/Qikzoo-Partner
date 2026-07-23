import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/orders/screens/orders_screen.dart';
import 'package:delivery_partner_app/models/orders/order_history_page_model.dart';
import 'package:delivery_partner_app/models/orders/rider_order_model.dart';
import 'package:delivery_partner_app/repositories/orders/rider_orders_repository.dart';

class FakeRiderOrdersRepository implements RiderOrdersRepository {
  FakeRiderOrdersRepository({this.activeOrder, this.pages = const {}});

  RiderOrderModel? activeOrder;
  final Map<OrderHistoryFilter, List<OrderHistoryPageModel>> pages;
  Object? historyError;
  final Map<OrderHistoryFilter, int> pageRequests = {};

  @override
  Future<List<RiderOrderModel>> getCurrent() async =>
      activeOrder == null ? [] : [activeOrder!];

  @override
  Future<RiderOrderModel> getOne(String riderOrderId) => throw UnimplementedError();

  @override
  Future<OrderHistoryPageModel> getHistory({
    required OrderHistoryFilter filter,
    required int page,
    required int pageSize,
  }) async {
    if (historyError != null) throw historyError!;
    // 1-indexed call count for this filter — the Nth call reads pages[N-1].
    final callNumber = pageRequests.update(filter, (v) => v + 1, ifAbsent: () => 1);
    final list = pages[filter] ?? const [];
    if (callNumber - 1 >= list.length) {
      return OrderHistoryPageModel(items: const [], total: 0, page: page, pageSize: pageSize);
    }
    return list[callNumber - 1];
  }

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

RiderOrderModel mockOrder({
  String id = 'rider-order-1',
  RiderOrderStatus status = RiderOrderStatus.delivered,
  String restaurantName = 'Spice Route Kitchen',
}) =>
    RiderOrderModel(
      id: id,
      orderId: 'order-$id',
      status: status,
      distanceKm: 2.5,
      earningsPaise: 4000,
      tipsPaise: 0,
      etaMinutes: null,
      assignedAt: DateTime(2026, 7, 23, 10),
      acceptedAt: null,
      arrivedAt: null,
      pickedUpAt: null,
      outForDeliveryAt: null,
      deliveredAt: null,
      cancelledAt: null,
      cancellationReason: null,
      restaurant: RestaurantContactModel(
        name: restaurantName,
        phone: '9000000001',
        address: '1 MG Road',
        landmark: null,
        latitude: 12.9,
        longitude: 77.6,
      ),
      order: const RestaurantOrderSummary(
        id: 'order-1',
        orderNumber: 'BR-1',
        customerName: 'Asha Rao',
        customerPhone: '9999999999',
        deliveryAddressLine: null,
        deliveryCity: null,
        deliveryPincode: null,
        deliveryLat: null,
        deliveryLng: null,
        totalPaise: 45000,
        customerNote: null,
        status: RestaurantOrderStatus.delivered,
        statusHistory: null,
      ),
      pickupQr: null,
      deliveryOtp: null,
    );

Widget buildApp({required FakeRiderOrdersRepository repository}) {
  return ProviderScope(
    overrides: [riderOrdersRepositoryProvider.overrideWithValue(repository)],
    child: GetMaterialApp(
      initialRoute: AppRoutes.orders,
      getPages: [
        GetPage(name: AppRoutes.orders, page: () => const OrdersScreen()),
        GetPage(
          name: AppRoutes.activeOrder,
          page: () => const Scaffold(body: Text('Active Order Screen')),
        ),
        GetPage(
          name: AppRoutes.orderDetails,
          page: () => Text('Order Details: ${Get.arguments}'),
        ),
      ],
    ),
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('shows the active-order banner when one exists, and navigates on tap',
      (tester) async {
    final repo = FakeRiderOrdersRepository(activeOrder: mockOrder(status: RiderOrderStatus.accepted));
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('You have an order in progress'), findsOneWidget);

    await tester.tap(find.text('You have an order in progress'));
    await tester.pumpAndSettle();

    expect(find.text('Active Order Screen'), findsOneWidget);
  });

  testWidgets('hides the active-order banner when there is none', (tester) async {
    final repo = FakeRiderOrdersRepository(activeOrder: null);
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('You have an order in progress'), findsNothing);
  });

  testWidgets('defaults to the Active tab and lists its orders', (tester) async {
    final repo = FakeRiderOrdersRepository(pages: {
      OrderHistoryFilter.active: [
        OrderHistoryPageModel(
          items: [mockOrder(restaurantName: 'Active Kitchen', status: RiderOrderStatus.accepted)],
          total: 1,
          page: 1,
          pageSize: 20,
        ),
      ],
    });
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Active Kitchen'), findsOneWidget);
  });

  testWidgets('switching tabs loads the Completed/Cancelled lists independently',
      (tester) async {
    final repo = FakeRiderOrdersRepository(pages: {
      OrderHistoryFilter.active: [
        const OrderHistoryPageModel(items: [], total: 0, page: 1, pageSize: 20),
      ],
      OrderHistoryFilter.completed: [
        OrderHistoryPageModel(
          items: [mockOrder(restaurantName: 'Completed Kitchen')],
          total: 1,
          page: 1,
          pageSize: 20,
        ),
      ],
      OrderHistoryFilter.cancelled: [
        OrderHistoryPageModel(
          items: [
            mockOrder(
              restaurantName: 'Cancelled Kitchen',
              status: RiderOrderStatus.cancelled,
            ),
          ],
          total: 1,
          page: 1,
          pageSize: 20,
        ),
      ],
    });
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('No active orders right now.'), findsOneWidget);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Completed Kitchen'), findsOneWidget);

    await tester.tap(find.text('Cancelled'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled Kitchen'), findsOneWidget);
  });

  testWidgets('tapping an order navigates to its details screen', (tester) async {
    final repo = FakeRiderOrdersRepository(pages: {
      OrderHistoryFilter.active: [
        OrderHistoryPageModel(
          items: [mockOrder(id: 'ro-42')],
          total: 1,
          page: 1,
          pageSize: 20,
        ),
      ],
    });
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spice Route Kitchen'));
    await tester.pumpAndSettle();

    expect(find.text('Order Details: ro-42'), findsOneWidget);
  });

  testWidgets('infinite scroll loads the next page near the bottom of the list',
      (tester) async {
    final firstPageItems =
        List.generate(20, (i) => mockOrder(id: 'ro-$i', restaurantName: 'Kitchen $i'));
    final secondPageItems = [mockOrder(id: 'ro-20', restaurantName: 'Kitchen 20')];
    final repo = FakeRiderOrdersRepository(pages: {
      OrderHistoryFilter.active: [
        OrderHistoryPageModel(items: firstPageItems, total: 21, page: 1, pageSize: 20),
        OrderHistoryPageModel(items: secondPageItems, total: 21, page: 2, pageSize: 20),
      ],
    });
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Kitchen 0'), findsOneWidget);

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(repo.pageRequests[OrderHistoryFilter.active], greaterThanOrEqualTo(2));
  });

  testWidgets('an empty tab shows the matching empty state message', (tester) async {
    final repo = FakeRiderOrdersRepository(pages: {
      OrderHistoryFilter.active: [
        const OrderHistoryPageModel(items: [], total: 0, page: 1, pageSize: 20),
      ],
    });
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('No active orders right now.'), findsOneWidget);
  });

  testWidgets('a history load failure shows Retry, which succeeds on retry', (tester) async {
    final repo = FakeRiderOrdersRepository()
      ..historyError = const ApiException(message: 'Unable to connect. Check your internet connection.');
    await tester.pumpWidget(buildApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('Unable to connect'), findsOneWidget);

    repo.historyError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('No active orders right now.'), findsOneWidget);
  });
}
