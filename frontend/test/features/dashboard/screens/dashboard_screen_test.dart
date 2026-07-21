import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:delivery_partner_app/features/authentication/widgets/signup_bonus_dialog.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_image_picker.dart';
import 'package:delivery_partner_app/shared/widgets/buttons/primary_cta_button.dart';

class FakeDocumentImagePicker implements DocumentImagePicker {
  @override
  Future<String?> pickImage(ImageSource source) async =>
      '/tmp/shift-selfie.jpg';
}

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp() => ProviderScope(
      overrides: [
        documentImagePickerProvider.overrideWithValue(
          FakeDocumentImagePicker(),
        ),
      ],
      child: GetMaterialApp(
        initialRoute: AppRoutes.dashboard,
        getPages: [
          GetPage(
            name: AppRoutes.dashboard,
            page: () => const DashboardScreen(),
          ),
        ],
      ),
    );

// The Home has continuously-running animations (waiting radar, countdown ring),
// so pumpAndSettle would never settle. Advance a bounded amount instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> goOnline(WidgetTester tester) async {
  await tester.tap(find.text('Go Online'));
  await settle(tester);
  expect(find.text('One quick check before\nyou go online'), findsOneWidget);

  await tester.tap(find.text('Tap to open camera'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Use Selfie & Go Online'));
  await tester.pump(const Duration(milliseconds: 400));
  await settle(tester);
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('starts offline showing the offline hero', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text("You're offline"), findsOneWidget);
    expect(find.byType(SignupBonusDialog), findsNothing);
  });

  testWidgets('Go Online requires the white T-shirt selfie check',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go Online'));
    await settle(tester);

    expect(find.text('Use Selfie & Go Online'), findsOneWidget);
    expect(find.text('White T-shirt'), findsOneWidget);
    final disabledButton = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(disabledButton.onPressed, isNull);
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
