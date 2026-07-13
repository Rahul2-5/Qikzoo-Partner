import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/order_details_card.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/customer_location_card.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/earnings_strip.dart';
import 'package:delivery_partner_app/models/orders/order_model.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('OrderDetailsCard copies order id to clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    await tester.pumpWidget(wrap(OrderDetailsCard(order: OrderModel.mock())));
    await tester.tap(find.text('Copy'));
    await tester.pump();
    expect(copied, '#171287364912');
    expect(find.text('Order ID copied'), findsOneWidget);
  });

  testWidgets('OrderDetailsCard expands items on tap', (tester) async {
    await tester.pumpWidget(wrap(OrderDetailsCard(order: OrderModel.mock())));
    expect(find.text('1 x Chicken Biryani, 1 x Raita, 1 x Coke'), findsOneWidget);
  });

  testWidgets('EarningsStrip shows precise amount', (tester) async {
    await tester.pumpWidget(wrap(const EarningsStrip(amount: 38.5)));
    expect(find.text('₹38.50'), findsOneWidget);
    expect(find.text('View detail'), findsOneWidget);
  });

  testWidgets('CustomerLocationCard shows address and Navigate', (tester) async {
    await tester.pumpWidget(wrap(const CustomerLocationCard(
      title: 'Customer Location',
      address: 'Sundervan Complex, Andheri West',
      pincode: '400058',
      etaLine: '4.2 km away · 12 mins',
    )));
    expect(find.text('Customer Location'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('4.2 km away · 12 mins'), findsOneWidget);
  });
}
