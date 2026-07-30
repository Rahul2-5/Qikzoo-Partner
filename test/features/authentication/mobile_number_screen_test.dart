import 'dart:async';

import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/core/theme/app_theme.dart';
import 'package:delivery_partner_app/features/authentication/screens/mobile_number_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_flow.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/shared/widgets/buttons/primary_cta_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class FakeAuthRepository implements AuthRepository {
  String? requestedPhone;
  int requestCount = 0;

  @override
  Future<OtpModel> requestOtp(String phoneNumber) async {
    requestedPhone = phoneNumber;
    requestCount++;
    return OtpModel(
      phoneNumber: phoneNumber,
      isVerified: false,
      expiresAt: DateTime(2030),
    );
  }

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp,
          {String? name}) =>
      throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();
}

class PendingAuthRepository extends FakeAuthRepository {
  final completer = Completer<OtpModel>();

  @override
  Future<OtpModel> requestOtp(String phoneNumber) {
    requestedPhone = phoneNumber;
    requestCount++;
    return completer.future;
  }

  void complete() {
    completer.complete(
      OtpModel(
        phoneNumber: requestedPhone!,
        isVerified: false,
        expiresAt: DateTime(2030),
      ),
    );
  }
}

class FailingAuthRepository extends FakeAuthRepository {
  @override
  Future<OtpModel> requestOtp(String phoneNumber) {
    requestedPhone = phoneNumber;
    requestCount++;
    throw const ApiException(
        message: 'OTP service is temporarily unavailable.');
  }
}

void setPhoneSurface(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp(
  AuthRepository repository, {
  AuthFlow flow = AuthFlow.login,
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: GetMaterialApp(
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
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

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('shows the Qikzoo logo and a single mobile-number field',
      (tester) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(buildApp(FakeAuthRepository()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('PARTNER LOGIN'), findsOneWidget);
    expect(
      find.text('We will send a 4-digit OTP to verify this number.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Full name'), findsNothing);
    expect(find.text('Enter your full name'), findsNothing);

    final button = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('a valid signup number forwards its flow to OTP', (tester) async {
    setPhoneSurface(tester);
    final repository = FakeAuthRepository();
    await tester.pumpWidget(buildApp(repository, flow: AuthFlow.signUp));

    expect(find.text('Create your partner account'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();

    expect(find.text('Number looks good'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(repository.requestedPhone, '9876543210');
    expect(find.text('Signup OTP destination'), findsOneWidget);
  });

  testWidgets('invalid number shows a snackbar after Continue is tapped',
      (tester) async {
    setPhoneSurface(tester);
    final repository = FakeAuthRepository();
    await tester.pumpWidget(buildApp(repository));

    await tester.enterText(find.byType(TextField), '9999999999');
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Please enter a valid mobile number.'), findsOneWidget);
    expect(repository.requestedPhone, isNull);
  });

  testWidgets(
      'compact layout remains scrollable and accessible with large text',
      (tester) async {
    setPhoneSurface(tester, size: const Size(320, 568));
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      buildApp(
        FakeAuthRepository(),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('mobile-number-scroll-view')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Qikzoo Delivery Partner'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp('Indian mobile number, country code plus 91'),
      ),
      findsOneWidget,
    );
    expect(find.text('Continue'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('mobile-number-scroll-view')),
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'By continuing, you agree to Qikzoo Terms and Conditions.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('loading state prevents duplicate OTP requests', (tester) async {
    setPhoneSurface(tester);
    final repository = PendingAuthRepository();
    await tester.pumpWidget(buildApp(repository, flow: AuthFlow.signUp));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(repository.requestCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(PrimaryCtaButton));
    await tester.pump();
    expect(repository.requestCount, 1);

    repository.complete();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Signup OTP destination'), findsOneWidget);
  });

  testWidgets('API errors are shown and the form becomes interactive again',
      (tester) async {
    setPhoneSurface(tester);
    final repository = FailingAuthRepository();
    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.requestCount, 1);
    expect(
      find.text('OTP service is temporarily unavailable.'),
      findsOneWidget,
    );
    expect(find.text('Login OTP destination'), findsNothing);

    final button = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(button.isLoading, isFalse);
    expect(button.onPressed, isNotNull);
  });
}
