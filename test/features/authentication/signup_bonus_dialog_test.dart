import 'package:delivery_partner_app/core/utils/currency_formatter.dart';
import 'package:delivery_partner_app/features/authentication/widgets/signup_bonus_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
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
}
