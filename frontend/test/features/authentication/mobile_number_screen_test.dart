import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/authentication/screens/mobile_number_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/auth_flow.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/shared/widgets/buttons/primary_cta_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class FakeAuthRepository implements AuthRepository {
  String? requestedPhone;

  @override
  Future<OtpModel> requestOtp(String phoneNumber) async {
    requestedPhone = phoneNumber;
    return OtpModel(
      phoneNumber: phoneNumber,
      isVerified: false,
      expiresAt: DateTime(2030),
    );
  }

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp) {
    throw UnimplementedError();
  }
}

void setPhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp(
  FakeAuthRepository repository, {
  AuthFlow flow = AuthFlow.login,
}) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: GetMaterialApp(
      initialRoute: AppRoutes.otp,
      getPages: [
        GetPage(
          name: AppRoutes.otp,
          page: () => MobileNumberScreen(flow: flow),
        ),
        GetPage(
          name: AppRoutes.otpVerification,
          page: () => Scaffold(
            body: Text(
              Get.parameters['flow'] == 'signup'
                  ? 'Signup OTP destination'
                  : 'Login OTP destination',
            ),
          ),
        ),
      ],
    ),
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('shows enhanced secure mobile-number entry state',
      (tester) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(buildApp(FakeAuthRepository()));

    expect(find.text('SECURE SIGN IN'), findsOneWidget);
    expect(find.text('Secure login'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('Enter a valid 10-digit Indian number'), findsOneWidget);

    final button = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('valid signup number forwards its flow to OTP', (tester) async {
    setPhoneSurface(tester);
    final repository = FakeAuthRepository();
    await tester.pumpWidget(buildApp(repository, flow: AuthFlow.signUp));

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();

    expect(find.text('Number looks good'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(repository.requestedPhone, '9876543210');
    expect(find.text('Signup OTP destination'), findsOneWidget);
  });
}
