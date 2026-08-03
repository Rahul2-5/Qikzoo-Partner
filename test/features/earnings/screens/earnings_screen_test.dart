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

Widget buildApp({TextScaler textScaler = TextScaler.noScaling}) =>
    GetMaterialApp(
      initialRoute: AppRoutes.earnings,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child ?? const SizedBox.shrink(),
      ),
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
    expect(find.text("Today's Earnings"), findsOneWidget);
    expect(find.text('Cash limit'), findsOneWidget);
    expect(find.text('Deposit cash'), findsOneWidget);
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

  testWidgets('remains usable on compact screens with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp(textScaler: const TextScaler.linear(1.5)));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text("Today's Earnings"), findsOneWidget);
    expect(find.text('Gig Progress'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
