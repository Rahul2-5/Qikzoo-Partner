import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/authentication/screens/otp_verification_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_flow.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
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
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp) async {
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
  for (final digit in ['1', '2', '3', '4']) {
    await tester.tap(find.text(digit));
    await tester.pump();
  }
  await tester.pumpAndSettle();
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
