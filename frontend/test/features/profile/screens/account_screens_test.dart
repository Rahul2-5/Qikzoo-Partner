import 'package:delivery_partner_app/core/theme/app_theme.dart';
import 'package:delivery_partner_app/features/bank_details/screens/bank_details_screen.dart';
import 'package:delivery_partner_app/features/documents/screens/manage_documents_screen.dart';
import 'package:delivery_partner_app/features/settings/screens/settings_screen.dart';
import 'package:delivery_partner_app/features/support/screens/help_support_screen.dart';
import 'package:delivery_partner_app/features/vehicle_details/screens/manage_vehicle_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Widget _buildScreen(Widget screen) {
  return ProviderScope(
    child: GetMaterialApp(
      theme: AppTheme.light,
      home: screen,
    ),
  );
}

Future<void> _loadScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_buildScreen(screen));
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bank details screen loads the saved payout account',
      (tester) async {
    await _loadScreen(tester, const BankDetailsScreen());

    expect(find.text('Account information'), findsOneWidget);
    expect(find.text('UPI (optional)'), findsOneWidget);
    expect(find.text('Save bank details'), findsOneWidget);
  });

  testWidgets('vehicle details screen loads the active vehicle',
      (tester) async {
    await _loadScreen(tester, const ManageVehicleDetailsScreen());

    expect(find.text('Bike / scooter'), findsOneWidget);
    expect(find.text('Vehicle information'), findsOneWidget);
    expect(find.text('Save vehicle details'), findsOneWidget);
  });

  testWidgets('documents screen groups identity and vehicle documents',
      (tester) async {
    await _loadScreen(tester, const ManageDocumentsScreen());

    expect(find.text('Identity documents'), findsOneWidget);
    expect(find.text('Aadhaar Card'), findsOneWidget);
    expect(find.text('Vehicle documents'), findsOneWidget);
  });

  testWidgets('support screen creates and displays a ticket', (tester) async {
    await _loadScreen(tester, const HelpSupportScreen());

    expect(find.text('No open tickets'), findsOneWidget);
    await tester.tap(find.text('Raise a support ticket'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Payout not received');
    await tester.pump();
    await tester.tap(find.text('Submit ticket'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    expect(find.text('Payout not received'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('settings screen does not offer language selection',
      (tester) async {
    await _loadScreen(tester, const SettingsScreen());

    expect(find.text('App language'), findsNothing);
    expect(find.text('Choose app language'), findsNothing);
    expect(find.text('Push notifications'), findsOneWidget);
    expect(find.text('Security & privacy'), findsOneWidget);
  });
}
