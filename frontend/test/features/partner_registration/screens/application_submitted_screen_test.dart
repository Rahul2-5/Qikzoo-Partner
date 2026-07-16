import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/application_submitted_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp() {
  return GetMaterialApp(
    initialRoute: AppRoutes.applicationSubmitted,
    getPages: [
      GetPage(
        name: AppRoutes.applicationSubmitted,
        page: () => const ApplicationSubmittedScreen(),
      ),
      GetPage(
        name: AppRoutes.dashboard,
        page: () => const Scaffold(body: Text('Dashboard Screen')),
      ),
    ],
  );
}

void main() {
  testWidgets('renders confirmation and has no manual Home button',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.text('Payment successful'), findsOneWidget);
    expect(find.text('Application Submitted'), findsOneWidget);
    expect(find.text('Document verification (1–2 days)'), findsOneWidget);
    expect(find.text('Background verification'), findsOneWidget);
    expect(find.text('Activation and training'), findsOneWidget);
    expect(find.text('Taking you to Home in 5 seconds…'), findsOneWidget);
    expect(find.text('Go to Home'), findsNothing);
  });

  testWidgets('automatically redirects to dashboard after five seconds',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Application Submitted'), findsOneWidget);
    expect(find.text('Dashboard Screen'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
  });
}
