import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/dashboard/screens/dashboard_screen.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp() => GetMaterialApp(
      initialRoute: AppRoutes.dashboard,
      getPages: [
        GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),
      ],
    );

// The Home has continuously-running animations (waiting radar, countdown ring),
// so pumpAndSettle would never settle. Advance a bounded amount instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> goOnline(WidgetTester tester) async {
  await tester.tap(find.text('Go Online'));
  await settle(tester); // confirmation dialog appears
  await tester.tap(find.text('Confirm'));
  await settle(tester); // dialog dismissed, waiting card shown
}

void main() {
  testWidgets('starts offline showing the offline hero', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text("You're offline"), findsOneWidget);
  });

  testWidgets('full happy path: offline → delivered → back to waiting',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await goOnline(tester);
    expect(find.text('Finding orders near you…'), findsOneWidget);

    // Simulated incoming order arrives after 2s, then the takeover slides in.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('New Order'), findsOneWidget);

    await tester.tap(find.text('Accept Order'));
    await settle(tester);
    expect(find.text('Navigate to Restaurant'), findsOneWidget);

    await tester.tap(find.text('Navigate to Restaurant'));
    await settle(tester);
    expect(find.text('Reached Restaurant'), findsOneWidget);

    await tester.tap(find.text('Reached Restaurant'));
    await settle(tester);
    // arrivedAtRestaurant → swipe to Confirm Pickup
    await tester.drag(find.text('Confirm Pickup'), const Offset(500, 0));
    await settle(tester);
    expect(find.text('Reached Customer'), findsOneWidget);

    await tester.tap(find.text('Reached Customer'));
    await settle(tester);
    // arrivedAtCustomer → swipe to Confirm Delivery
    await tester.drag(find.text('Confirm Delivery'), const Offset(500, 0));
    await settle(tester);
    expect(find.text('Order delivered successfully!'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Finding orders near you…'), findsOneWidget);
  });
}
