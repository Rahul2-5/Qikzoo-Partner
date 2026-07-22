import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/onboarding_welcome/screens/onboarding_welcome_screen.dart';
import 'package:delivery_partner_app/features/onboarding_welcome/screens/partner_benefits_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp() {
  return GetMaterialApp(
    initialRoute: AppRoutes.welcome,
    getPages: [
      GetPage(
        name: AppRoutes.welcome,
        page: () => const OnboardingWelcomeScreen(),
      ),
      GetPage(
        name: AppRoutes.partnerBenefits,
        page: () => const PartnerBenefitsScreen(),
      ),
      GetPage(
        name: AppRoutes.otp,
        page: () => const Scaffold(body: Text('Mobile Number Screen')),
      ),
    ],
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('welcome screen presents the value proposition and benefits',
      (tester) async {
    setSurface(tester, const Size(400, 900));
    await tester.pumpWidget(buildApp());

    expect(find.text('QIKZOO'), findsOneWidget);
    expect(
      find.text('Deliver more.\nEarn on your terms.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Flexible\nhours'), findsOneWidget);
    expect(find.text('Weekly\npayouts'), findsOneWidget);
    expect(find.text('Start earning with Qikzoo'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 1 of 2'), findsOneWidget);
  });

  testWidgets('primary welcome action advances to partner benefits',
      (tester) async {
    setSurface(tester, const Size(400, 900));
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('Start earning with Qikzoo'));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME TO QIKZOO'), findsOneWidget);
    expect(
      find.text('Medical & health insurance'),
      findsOneWidget,
    );
    expect(find.text('COVER UP TO ₹15 LAKH'), findsOneWidget);
    expect(find.text('Flexible earning'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 2 of 2'), findsOneWidget);
  });

  testWidgets('benefits continue directly to signup mobile number',
      (tester) async {
    setSurface(tester, const Size(400, 900));
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('Start earning with Qikzoo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Mobile Number Screen'), findsOneWidget);
    expect(Get.parameters['flow'], 'signup');
  });

  testWidgets('existing partner login opens the login flow', (tester) async {
    setSurface(tester, const Size(400, 900));
    await tester.pumpWidget(buildApp());

    await tester.tap(find.bySemanticsLabel('Already a partner? Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Mobile Number Screen'), findsOneWidget);
    expect(Get.parameters['flow'], 'login');
  });

  testWidgets('compact phone viewport has no layout exceptions',
      (tester) async {
    setSurface(tester, const Size(360, 640));
    await tester.pumpWidget(buildApp());

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Start earning with Qikzoo'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
