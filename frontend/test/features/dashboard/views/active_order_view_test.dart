import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/views/active_order_view.dart';
import 'package:delivery_partner_app/models/orders/order_model.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget host(OrderModel order, VoidCallback onAdvance) => MaterialApp(
      home: Scaffold(
        body: ActiveOrderView(order: order, onAdvance: onAdvance),
      ),
    );

void main() {
  test('cta labels map to status', () {
    expect(ActiveOrderView.ctaLabelFor(OrderStatus.accepted),
        'Navigate to Restaurant');
    expect(ActiveOrderView.ctaLabelFor(OrderStatus.navigatingToRestaurant),
        'Reached Restaurant');
    expect(ActiveOrderView.ctaLabelFor(OrderStatus.arrivedAtRestaurant),
        'Confirm Pickup');
    expect(ActiveOrderView.ctaLabelFor(OrderStatus.navigatingToCustomer),
        'Reached Customer');
    expect(ActiveOrderView.ctaLabelFor(OrderStatus.arrivedAtCustomer),
        'Confirm Delivery');
  });

  test('swipe statuses are the two confirm actions', () {
    expect(
        ActiveOrderView.isSwipeStatus(OrderStatus.arrivedAtRestaurant), true);
    expect(ActiveOrderView.isSwipeStatus(OrderStatus.arrivedAtCustomer), true);
    expect(ActiveOrderView.isSwipeStatus(OrderStatus.accepted), false);
  });

  testWidgets('tap CTA advances', (tester) async {
    setTallSurface(tester);
    var advanced = 0;
    await tester.pumpWidget(host(
        OrderModel.mock().copyWith(status: OrderStatus.accepted),
        () => advanced++));
    await tester.tap(find.text('Navigate to Restaurant'));
    expect(advanced, 1);
  });

  testWidgets('restaurant phase shows pickup header', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(
        host(OrderModel.mock().copyWith(status: OrderStatus.accepted), () {}));
    expect(find.text('Pick up order'), findsOneWidget);
  });

  testWidgets('customer phase shows on-the-way header', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(host(
        OrderModel.mock().copyWith(status: OrderStatus.navigatingToCustomer),
        () {}));
    expect(find.text('Order picked up'), findsOneWidget);
  });

  testWidgets('wide active-order workspace renders without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host(
      OrderModel.mock().copyWith(status: OrderStatus.accepted),
      () {},
    ));

    expect(find.text('Restaurant Location'), findsOneWidget);
    expect(find.text('Estimated Earning'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
