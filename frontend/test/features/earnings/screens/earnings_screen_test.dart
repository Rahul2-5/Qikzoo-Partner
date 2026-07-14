import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/earnings/screens/earnings_screen.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp() => GetMaterialApp(
      initialRoute: AppRoutes.earnings,
      getPages: [
        GetPage(name: AppRoutes.earnings, page: () => const EarningsScreen()),
        GetPage(
            name: AppRoutes.dashboard,
            page: () => const Scaffold(body: Text('Dashboard Screen'))),
        GetPage(
            name: AppRoutes.orders,
            page: () => const Scaffold(body: Text('Orders Screen'))),
        GetPage(
            name: AppRoutes.profile,
            page: () => const Scaffold(body: Text('Profile Screen'))),
      ],
    );

void main() {
  testWidgets('renders this-week total by default', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('₹2,345.50'), findsWidgets);
  });

  testWidgets('switching period updates the total', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('This Week').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('This Month').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('₹7,630.75'), findsWidgets);
  });

  testWidgets('tapping the Home tab navigates to the dashboard',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Screen'), findsOneWidget);
  });
}
