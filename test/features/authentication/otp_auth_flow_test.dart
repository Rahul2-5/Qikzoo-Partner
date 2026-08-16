import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/authentication/screens/otp_verification_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_flow.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/providers/authentication/auth_provider.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class SuccessfulAuthRepository implements AuthRepository {
  @override
  Future<OtpModel> requestOtp(String phoneNumber) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp, {String? name}) async {
    return const AuthSessionModel(
      partnerId: 'partner_1',
      token: 'token',
      isAuthenticated: true,
    );
  }

  @override
  Future<void> logout() => throw UnimplementedError();
}

Widget buildFlow(AuthFlow flow) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(SuccessfulAuthRepository()),
      // The real mobile-number screen sets this as the rider types (see
      // mobile_number_screen.dart), and it's what the OTP screen's _phone
      // getter reads first — without it, _onOtpCompleted bails out early on
      // "Phone number missing" and verifyOtp() is never actually invoked.
      phoneNumberUiProvider.overrideWith((ref) => '9876543210'),
    ],
    child: GetMaterialApp(
      initialRoute: '/verify',
      getPages: [
        GetPage(
          name: '/verify',
          page: () => OtpVerificationScreen(flow: flow),
        ),
        GetPage(
          name: AppRoutes.dashboard,
          page: () => const Scaffold(body: Text('Dashboard destination')),
        ),
        GetPage(
          name: AppRoutes.setPassword,
          page: () => const Scaffold(body: Text('Password destination')),
        ),
      ],
    ),
  );
}

Future<void> enterOtp(WidgetTester tester) async {
  // The OTP screen uses pin_code_fields' PinCodeTextField, which renders
  // one underlying TextFormField per box and distributes pasted/entered
  // text across all of them from the first field, not tappable digit
  // buttons. Its active-box cursor animation repeats
  // indefinitely once focused, so pumpAndSettle() never converges —
  // bounded pumps drive the same frames without waiting on it.
  await tester.enterText(find.byType(TextFormField).first, '1234');
  await tester.pump();
  // Bounded, not pumpAndSettle: enough for the verify call plus the page
  // transition's own animation to finish landing on the next route.
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('signup OTP continues to password setup', (tester) async {
    await tester.pumpWidget(buildFlow(AuthFlow.signUp));

    await enterOtp(tester);

    expect(find.text('Password destination'), findsOneWidget);
    expect(find.text('Dashboard destination'), findsNothing);
  });

  testWidgets('login OTP continues directly to dashboard', (tester) async {
    await tester.pumpWidget(buildFlow(AuthFlow.login));

    await enterOtp(tester);

    expect(find.text('Dashboard destination'), findsOneWidget);
    expect(find.text('Password destination'), findsNothing);
  });
}
