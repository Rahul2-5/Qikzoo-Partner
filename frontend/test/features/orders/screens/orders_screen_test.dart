import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/orders/screens/orders_screen.dart';
import 'package:delivery_partner_app/features/orders/widgets/orders_tab_bar.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp() => GetMaterialApp(
      initialRoute: AppRoutes.orders,
      getPages: [
        GetPage(name: AppRoutes.orders, page: () => const OrdersScreen()),
        GetPage(
            name: AppRoutes.dashboard,
            page: () => const Scaffold(body: Text('Dashboard Screen'))),
        GetPage(
            name: AppRoutes.earnings,
            page: () => const Scaffold(body: Text('Earnings Screen'))),
        GetPage(
            name: AppRoutes.profile,
            page: () => const Scaffold(body: Text('Profile Screen'))),
      ],
    );

void main() {
  testWidgets('defaults to All and shows both date groups', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('Today, 12 May 2025'), findsOneWidget);
    expect(find.text('Yesterday, 11 May 2025'), findsOneWidget);
  });

  testWidgets('Cancelled tab shows only the cancelled entry', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final cancelledTab = find.descendant(
        of: find.byType(OrdersTabBar), matching: find.text('Cancelled'));
    await tester.ensureVisible(cancelledTab);
    await tester.pumpAndSettle();
    await tester.tap(cancelledTab);
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsWidgets); // tab + badge/rail
    expect(find.text('Cake Studio'), findsOneWidget);
    expect(find.text('Burger Point'), findsNothing);
  });

  testWidgets('search narrows to Burger Point', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'burger');
    await tester.pumpAndSettle();
    expect(find.text('Burger Point'), findsOneWidget);
    expect(find.text('Pizza Corner'), findsNothing);
  });

  testWidgets('empty query result shows the empty state', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pumpAndSettle();
    expect(find.text('No orders here yet'), findsOneWidget);
  });

  testWidgets('Home tab navigates to the dashboard', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Screen'), findsOneWidget);
  });
}
