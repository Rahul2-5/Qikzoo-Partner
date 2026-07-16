import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/views/order_delivered_view.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/rating_selector.dart';
import 'package:delivery_partner_app/models/orders/order_model.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('shows success amount and Continue', (tester) async {
    setTallSurface(tester);
    var continued = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OrderDeliveredView(
          order: OrderModel.mock(),
          onContinue: () => continued++,
        ),
      ),
    ));
    expect(find.text('Order delivered successfully!'), findsOneWidget);
    expect(find.text('₹38.50'), findsWidgets);
    await tester.tap(find.text('Continue'));
    expect(continued, 1);
  });

  testWidgets('RatingSelector selecting a star shows thanks', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: RatingSelector()),
    ));
    expect(find.text('Thanks for the feedback!'), findsNothing);
    await tester.tap(find.text('Good'));
    await tester.pump();
    expect(find.text('Thanks for the feedback!'), findsOneWidget);
  });

  testWidgets('wide delivered workspace renders without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OrderDeliveredView(
          order: OrderModel.mock(),
          onContinue: () {},
        ),
      ),
    ));

    expect(find.text('Earnings breakdown'), findsOneWidget);
    expect(find.byType(RatingSelector), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
