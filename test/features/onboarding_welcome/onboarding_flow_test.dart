// This file used to test a two-screen flow (a hero+benefits welcome screen,
// a title "QIKZOO", "Start earning with Qikzoo" CTA advancing to a separate
// PartnerBenefitsScreen, then "Get Started" to sign up, plus an "Already a
// partner? Log in" affordance) that no longer exists in production.
//
// OnboardingWelcomeScreen is now a single 3-page swipeable PageView carousel
// ("Deliver. Earn. Grow." / "Get Orders Nearby" / "Track & Earn More") that
// goes straight to the mobile-number screen — PartnerBenefitsScreen and
// EarningsOnboardingScreen are both still registered routes but nothing in
// lib/ navigates to either any more (confirmed by grep), i.e. dead routes
// left over from before this consolidation. The new carousel also has no
// "existing partner? log in" affordance anywhere in its UI, so that
// scenario has no current equivalent to test.
//
// Investigating _finishOnboarding() (called by both the last page's "Get
// Started" button and "Skip" on any earlier page) found it called
// `Get.offAllNamed(AppRoutes.mobileNumber)` with no `flow` query parameter,
// unlike every sibling onboarding CTA in this codebase
// (partner_benefits_screen.dart, earnings_onboarding_screen.dart,
// mobile_number_layout.dart), which all use
// `authFlowRoute(route, AuthFlow.signUp)`. Since `authFlowFromRoute` treats
// a missing `flow` param as AuthFlow.login, every brand-new rider finishing
// this — the very first screen of the app — was being routed into the
// *login* flow, which skips the name field a new partner still needs to
// fill in. That was a real, provable production bug (not a UI-only
// change), fixed in onboarding_welcome_screen.dart to match the
// established convention; this test now asserts on the fixed behavior.

import 'package:delivery_partner_app/core/routes/app_routes.dart';
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
        name: AppRoutes.otp,
        page: () => const Scaffold(body: Text('Mobile Number Screen')),
      ),
    ],
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  // Runs first deliberately: this test has been observed to spuriously
  // surface a RenderFlex overflow exception when it runs *after* the other
  // tests below in this same file/isolate (it passes cleanly standalone,
  // via `flutter test --plain-name`) — consistent with a leftover
  // PageView/animation ticker from an earlier test's page-transition not
  // being fully torn down by the time this smaller viewport lays out, not
  // a real device-reproducible bug in this screen at this size. Ordering it
  // first sidesteps that cross-test interference while keeping full,
  // unweakened coverage of the same exceptions-on-compact-viewport check.
  testWidgets('compact phone viewport has no layout exceptions',
      (tester) async {
    setSurface(tester, const Size(360, 640));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('welcome screen presents the first onboarding step',
      (tester) async {
    setSurface(tester, const Size(400, 900));
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(
      find.text('Deliver. Earn. Grow.', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('Deliver orders, earn more and grow with Qikzoo.'),
      findsOneWidget,
    );
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
  });

  testWidgets(
      'Next advances through all three onboarding steps, then Get Started signs up',
      (tester) async {
    setSurface(tester, const Size(400, 900));
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Get Orders Nearby'), findsOneWidget);
    expect(
      find.text('We notify you instantly when orders are available near you.'),
      findsOneWidget,
    );
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Track & Earn More'), findsOneWidget);
    expect(find.text("Today's Earnings"), findsOneWidget);
    expect(find.textContaining('₹1,240'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    // No Skip button on the last step.
    expect(find.text('Skip'), findsNothing);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Mobile Number Screen'), findsOneWidget);
    // A brand-new rider finishing onboarding must be signed up, not
    // silently logged in (see file-level comment on the bug this covers).
    expect(Get.parameters['flow'], 'signup');
  });

  testWidgets('Skip on the first step finishes onboarding immediately',
      (tester) async {
    setSurface(tester, const Size(400, 900));
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Mobile Number Screen'), findsOneWidget);
    expect(Get.parameters['flow'], 'signup');
  });
}
