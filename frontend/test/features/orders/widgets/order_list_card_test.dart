import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/orders/widgets/order_list_card.dart';
import 'package:delivery_partner_app/models/orders/order_list_entry.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  final upcoming =
      OrderListEntry.mockList().firstWhere((e) => e.status == OrderListStatus.upcoming);
  final completed =
      OrderListEntry.mockList().firstWhere((e) => e.status == OrderListStatus.completed);

  testWidgets('renders id, restaurant, badge and amount', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(wrap(OrderListCard(entry: upcoming, onTap: () {})));
    expect(find.text(upcoming.id), findsOneWidget);
    expect(find.text('The Biryani House'), findsWidgets);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('₹38.50'), findsOneWidget);
  });

  testWidgets('upcoming shows View Details, completed does not', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(wrap(OrderListCard(entry: upcoming, onTap: () {})));
    expect(find.text('View Details'), findsOneWidget);

    await tester.pumpWidget(wrap(OrderListCard(entry: completed, onTap: () {})));
    expect(find.text('View Details'), findsNothing);
  });

  testWidgets('tapping the card fires onTap', (tester) async {
    setTallSurface(tester);
    var taps = 0;
    await tester.pumpWidget(wrap(OrderListCard(entry: completed, onTap: () => taps++)));
    await tester.tap(find.text(completed.id));
    expect(taps, 1);
  });
}
