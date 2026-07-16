import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/onboarding_welcome/screens/join_as_partner_screen.dart';
import 'package:delivery_partner_app/features/onboarding_welcome/screens/onboarding_welcome_screen.dart';
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
        name: AppRoutes.becomePartnerIntro,
        page: () => const JoinAsPartnerScreen(),
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
  });

  testWidgets('primary welcome action advances to partner introduction',
      (tester) async {
    setSurface(tester, const Size(400, 900));
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('Start earning with Qikzoo'));
    await tester.pumpAndSettle();

    expect(find.text('BECOME A QIKZOO PARTNER'), findsOneWidget);
    expect(find.text('Built for your day'), findsOneWidget);
    expect(find.text('Continue with mobile number'), findsOneWidget);
  });

  testWidgets('partner introduction continues to mobile number',
      (tester) async {
    setSurface(tester, const Size(400, 900));
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('Start earning with Qikzoo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with mobile number'));
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
  });
}
