import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/payment_status_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('payment coming soon advances to application under review',
      (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const PaymentComingSoonScreen(
          redirectDelay: Duration(milliseconds: 100),
        ),
        getPages: [
          GetPage(
            name: AppRoutes.applicationUnderReview,
            page: () => ApplicationUnderReviewScreen(
              submittedAt: DateTime(2026, 7, 23),
            ),
          ),
        ],
      ),
    );

    expect(find.text('Payments are coming soon'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Application under review'), findsOneWidget);
    expect(find.text('Submitted on 23 Jul 2026'), findsOneWidget);
  });

  testWidgets(
      '"View application status" leaves the under-review dead end and opens Verification Status',
      (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: ApplicationUnderReviewScreen(submittedAt: DateTime(2026, 7, 23)),
        getPages: [
          GetPage(
            name: AppRoutes.verificationStatus,
            page: () => const Scaffold(body: Text('Verification Status Screen')),
          ),
        ],
      ),
    );

    await tester.tap(find.text('View application status'));
    await tester.pumpAndSettle();

    expect(find.text('Verification Status Screen'), findsOneWidget);
  });
}
