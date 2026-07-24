import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/welcome_kit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp({WelcomeKitPaymentHandler? onPay}) {
  return GetMaterialApp(
    home: WelcomeKitScreen(onPay: onPay),
    getPages: [
      GetPage(
        name: AppRoutes.paymentComingSoon,
        page: () => const Scaffold(body: Text('Coming Soon Screen')),
      ),
    ],
  );
}

void main() {
  testWidgets('renders kit, both plans, and supported payment methods',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Your Welcome Kit is ready'), findsOneWidget);
    expect(find.text('Pay in full'), findsOneWidget);
    expect(find.text('Pay over 3 months'), findsOneWidget);
    expect(find.text('UPI'), findsOneWidget);
    expect(find.text('Credit or debit card'), findsOneWidget);
    expect(find.text('Pay ₹799 securely'), findsOneWidget);
  });

  testWidgets('installment selection charges the first exact installment',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('three-month-plan')));
    await tester.pumpAndSettle();

    expect(find.text('Pay ₹267 securely'), findsOneWidget);
    expect(
      find.text('Then ₹266/month for 2 months • ₹799 total'),
      findsOneWidget,
    );
  });

  testWidgets(
      'with no live payment gateway wired up, tapping Pay goes straight to Coming Soon without faking a transaction',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pay ₹799 securely'));
    // Advance only far enough for the page-transition animation itself —
    // nowhere near the old 900ms simulated processing delay — proving
    // there is no fake payment-processing step in between.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Coming Soon Screen'), findsOneWidget);
  });

  testWidgets('successful card payment opens the Coming Soon screen',
      (tester) async {
    setTallSurface(tester);
    WelcomeKitPlan? paidPlan;
    WelcomeKitPaymentMethod? paidMethod;

    await tester.pumpWidget(
      buildApp(
        onPay: (plan, method) async {
          paidPlan = plan;
          paidMethod = method;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('card-payment-method')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay ₹799 securely'));
    await tester.pumpAndSettle();

    expect(paidPlan, WelcomeKitPlan.fullPayment);
    expect(paidMethod, WelcomeKitPaymentMethod.card);
    expect(find.text('Coming Soon Screen'), findsOneWidget);
  });
}
