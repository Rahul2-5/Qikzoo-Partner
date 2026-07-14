import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/orders/widgets/orders_header.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows the My Orders title and toggles search', (tester) async {
    var toggled = 0;
    await tester.pumpWidget(wrap(OrdersHeader(
      searchOpen: false,
      query: '',
      onToggleSearch: () => toggled++,
      onQueryChanged: (_) {},
      onOpenFilter: () {},
    )));
    expect(find.text('My Orders'), findsOneWidget);
    await tester.tap(find.byTooltip('Search'));
    expect(toggled, 1);
  });

  testWidgets('shows the search field when open', (tester) async {
    await tester.pumpWidget(wrap(OrdersHeader(
      searchOpen: true,
      query: '',
      onToggleSearch: () {},
      onQueryChanged: (_) {},
      onOpenFilter: () {},
    )));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('filter button fires onOpenFilter', (tester) async {
    var opened = 0;
    await tester.pumpWidget(wrap(OrdersHeader(
      searchOpen: false,
      query: '',
      onToggleSearch: () {},
      onQueryChanged: (_) {},
      onOpenFilter: () => opened++,
    )));
    await tester.tap(find.byTooltip('Filter'));
    expect(opened, 1);
  });
}
