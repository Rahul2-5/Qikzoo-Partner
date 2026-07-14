import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp() => GetMaterialApp(
      initialRoute: AppRoutes.profile,
      getPages: [
        GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
        GetPage(
            name: AppRoutes.dashboard,
            page: () => const Scaffold(body: Text('Dashboard Screen'))),
        GetPage(
            name: AppRoutes.earnings,
            page: () => const Scaffold(body: Text('Earnings Screen'))),
        GetPage(
            name: AppRoutes.orders,
            page: () => const Scaffold(body: Text('Orders Screen'))),
        GetPage(
            name: AppRoutes.settings,
            page: () => const Scaffold(body: Text('Settings Screen'))),
        GetPage(
            name: AppRoutes.welcome,
            page: () => const Scaffold(body: Text('Welcome Screen'))),
      ],
    );

void main() {
  testWidgets('ProfileScreen renders the complete menu', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());

    expect(find.text('Rahul Verma'), findsOneWidget);
    for (final title in [
      'Personal Information',
      'Bank Details',
      'Vehicle Details',
      'Documents',
      'Incentives & Offers',
      'Help & Support',
      'Settings',
      'Log Out',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('Settings menu navigates to the settings route', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings Screen'), findsOneWidget);
  });

  testWidgets('Home tab navigates to the dashboard', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
  });

  testWidgets('Log Out opens confirmation and returns to welcome on confirm',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Screen'), findsOneWidget);
  });
}
