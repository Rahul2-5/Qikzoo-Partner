import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/application_submitted_screen.dart';

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
  testWidgets('renders the confirmation copy and next-steps card', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Application Submitted'), findsWidgets);
    expect(
      find.text('We will verify your details and get back to you soon.'),
      findsOneWidget,
    );
    expect(find.text('Document verification (1–2 days)'), findsOneWidget);
    expect(find.text('Background verification'), findsOneWidget);
    expect(find.text('Activation and training'), findsOneWidget);
    expect(find.text('Go to Home'), findsOneWidget);
  });

  testWidgets('Go to Home navigates to the dashboard', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go to Home'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
  });
}
