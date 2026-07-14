import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/orders/widgets/orders_tab_bar.dart';
import 'package:delivery_partner_app/features/orders/widgets/date_group_header.dart';
import 'package:delivery_partner_app/features/orders/widgets/orders_support_banner.dart';
import 'package:delivery_partner_app/models/orders/order_list_entry.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('OrdersTabBar renders four labels and reports taps',
      (tester) async {
    OrdersTab? picked;
    await tester.pumpWidget(wrap(OrdersTabBar(
      current: OrdersTab.all,
      onChanged: (t) => picked = t,
    )));
    expect(find.text('All Orders'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    await tester.tap(find.text('Cancelled'));
    expect(picked, OrdersTab.cancelled);
  });

  testWidgets('DateGroupHeader shows the label', (tester) async {
    await tester.pumpWidget(wrap(const DateGroupHeader(label: 'Today, 12 May 2025')));
    expect(find.text('Today, 12 May 2025'), findsOneWidget);
  });

  testWidgets('OrdersSupportBanner fires Get Support', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(wrap(OrdersSupportBanner(onGetSupport: () => tapped++)));
    await tester.tap(find.text('Get Support'));
    expect(tapped, 1);
  });
}
