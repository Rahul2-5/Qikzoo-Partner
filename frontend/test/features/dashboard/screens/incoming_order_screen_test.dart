import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/screens/incoming_order_screen.dart';
import 'package:delivery_partner_app/models/orders/order_model.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<bool?> pushScreen(WidgetTester tester, {int seconds = 30}) async {
  bool? result;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => IncomingOrderScreen(
                      order: OrderModel.mock(), seconds: seconds),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pump(); // start the push
  await tester.pump(const Duration(milliseconds: 400)); // finish push transition
  return result;
}

void main() {
  testWidgets('Accept pops true', (tester) async {
    setTallSurface(tester);
    await pushScreen(tester);
    expect(find.text('New Order'), findsOneWidget);
    await tester.tap(find.text('Accept Order'));
    await tester.pumpAndSettle();
    expect(find.text('New Order'), findsNothing);
  });

  testWidgets('Reject pops false', (tester) async {
    setTallSurface(tester);
    await pushScreen(tester);
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    expect(find.text('New Order'), findsNothing);
  });

  testWidgets('expiry auto-dismisses', (tester) async {
    setTallSurface(tester);
    await pushScreen(tester, seconds: 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('New Order'), findsNothing);
  });
}
