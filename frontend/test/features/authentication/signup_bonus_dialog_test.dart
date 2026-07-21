import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/core/utils/currency_formatter.dart';
import 'package:delivery_partner_app/features/authentication/screens/set_password_screen.dart';
import 'package:delivery_partner_app/features/authentication/widgets/signup_bonus_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

void setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildDialogApp() {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => SignupBonusDialog.show(context),
            child: const Text('Show bonus'),
          ),
        ),
      ),
    ),
  );
}

Widget buildPasswordFlow() {
  return GetMaterialApp(
    initialRoute: AppRoutes.setPassword,
    getPages: [
      GetPage(
        name: AppRoutes.setPassword,
        page: () => const SetPasswordScreen(),
      ),
      GetPage(
        name: AppRoutes.personalInfo,
        page: () => const Scaffold(body: Text('Personal info destination')),
      ),
    ],
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('presents the first-time signup reward accessibly',
      (tester) async {
    setSurface(tester, const Size(360, 640));
    await tester.pumpWidget(buildDialogApp());

    await tester.tap(find.text('Show bonus'));
    await tester.pumpAndSettle();

    expect(find.byType(SignupBonusDialog), findsOneWidget);
    expect(find.byIcon(LucideIcons.gift), findsOneWidget);
    expect(find.text('FIRST-TIME SIGNUP BONUS'), findsOneWidget);
    expect(find.text('Welcome to Qikzoo!'), findsOneWidget);
    expect(
      find.text(CurrencyFormatter.rupees(SignupBonusDialog.bonusAmount)),
      findsOneWidget,
    );
    expect(find.text('Start earning'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signup password completion continues without showing the bonus',
      (tester) async {
    setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(buildPasswordFlow());

    await tester.enterText(find.byType(TextField), 'Strong1!');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(SignupBonusDialog), findsNothing);
    expect(find.text('Personal info destination'), findsOneWidget);
  });
}
