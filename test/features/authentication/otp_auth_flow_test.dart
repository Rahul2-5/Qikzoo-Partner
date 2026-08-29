import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/authentication/screens/otp_verification_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_flow.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/onboarding_status/onboarding_status_model.dart';
import 'package:delivery_partner_app/models/partner_registration/personal_info_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/providers/authentication/auth_provider.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/onboarding_status/onboarding_status_repository.dart';
import 'package:delivery_partner_app/repositories/profile/profile_repository.dart';
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

// The real post-verification destination isn't a hardcoded route per
// AuthFlow (see NextOnboardingStepResolver): the OTP screen fetches the
// rider's profile + onboarding status and asks the resolver where to go.
// These fakes let each test control that outcome directly rather than
// re-deriving every resolver branch (already exhaustively covered by
// core/navigation/next_onboarding_step_resolver_test.dart).
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this._profile);
  final PartnerProfileModel _profile;

  @override
  Future<PartnerProfileModel> getProfile() async => _profile;

  @override
  Future<RatingModel> getRating() => throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updatePersonalDetails({
    required String name,
    String? email,
    required DateTime dateOfBirth,
    required Gender gender,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> uploadProfilePhoto(
    file, {
    void Function(int sent, int total)? onSendProgress,
    cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> uploadSelfie(
    file, {
    void Function(int sent, int total)? onSendProgress,
    cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updateAddress({
    required String addressLine1,
    String? addressLine2,
    String? landmark,
    required String city,
    required String state,
    required String pincode,
    double? addressLat,
    double? addressLng,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updateEmergencyContact({
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) =>
      throw UnimplementedError();
}

class FailingProfileRepository implements ProfileRepository {
  @override
  Future<PartnerProfileModel> getProfile() async =>
      throw Exception('network error');

  @override
  Future<RatingModel> getRating() => throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updatePersonalDetails({
    required String name,
    String? email,
    required DateTime dateOfBirth,
    required Gender gender,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> uploadProfilePhoto(
    file, {
    void Function(int sent, int total)? onSendProgress,
    cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> uploadSelfie(
    file, {
    void Function(int sent, int total)? onSendProgress,
    cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updateAddress({
    required String addressLine1,
    String? addressLine2,
    String? landmark,
    required String city,
    required String state,
    required String pincode,
    double? addressLat,
    double? addressLng,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updateEmergencyContact({
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) =>
      throw UnimplementedError();
}

class FakeOnboardingStatusRepository implements OnboardingStatusRepository {
  FakeOnboardingStatusRepository(this._status);
  final OnboardingStatusModel _status;

  @override
  Future<OnboardingStatusModel> getStatus() async => _status;

  @override
  Future<void> submitOnboarding({
    required String termsVersion,
    required String privacyPolicyVersion,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> reapply() => throw UnimplementedError();
}

final _emptyProfile = PartnerProfileModel(
  id: 'rider_1',
  name: '',
  phone: '9876543210',
  joinedDate: DateTime(2026, 1, 1),
);

Widget buildFlow(
  AuthFlow flow, {
  required ProfileRepository profileRepository,
  required OnboardingStatusRepository onboardingStatusRepository,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(SuccessfulAuthRepository()),
      // The real mobile-number screen sets this as the rider types (see
      // mobile_number_screen.dart), and it's what the OTP screen's _phone
      // getter reads first — without it, _onOtpCompleted bails out early on
      // "Phone number missing" and verifyOtp() is never actually invoked.
      phoneNumberUiProvider.overrideWith((ref) => '9876543210'),
      profileRepositoryProvider.overrideWithValue(profileRepository),
      onboardingStatusRepositoryProvider
          .overrideWithValue(onboardingStatusRepository),
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
          name: AppRoutes.personalInfo,
          page: () => const Scaffold(body: Text('Personal info destination')),
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

  testWidgets(
      'signup OTP for a rider still mid-onboarding continues to the resolved onboarding step',
      (tester) async {
    await tester.pumpWidget(buildFlow(
      AuthFlow.signUp,
      profileRepository: FakeProfileRepository(_emptyProfile),
      onboardingStatusRepository: FakeOnboardingStatusRepository(
        const OnboardingStatusModel(
          accountStatus: RiderAccountStatus.pendingKyc,
          onboardingStatus: RiderOnboardingStatus.inProgress,
          currentStep: 'PROFILE',
        ),
      ),
    ));

    await enterOtp(tester);

    expect(find.text('Personal info destination'), findsOneWidget);
    expect(find.text('Dashboard destination'), findsNothing);
  });

  testWidgets('login OTP for an already-active account continues directly to the dashboard',
      (tester) async {
    await tester.pumpWidget(buildFlow(
      AuthFlow.login,
      profileRepository: FakeProfileRepository(_emptyProfile),
      onboardingStatusRepository: FakeOnboardingStatusRepository(
        const OnboardingStatusModel(
          accountStatus: RiderAccountStatus.active,
          onboardingStatus: RiderOnboardingStatus.approved,
        ),
      ),
    ));

    await enterOtp(tester);

    expect(find.text('Dashboard destination'), findsOneWidget);
    expect(find.text('Personal info destination'), findsNothing);
  });

  testWidgets(
      'falls back to the dashboard if the profile/onboarding lookup fails after verification',
      (tester) async {
    await tester.pumpWidget(buildFlow(
      AuthFlow.login,
      profileRepository: FailingProfileRepository(),
      onboardingStatusRepository: FakeOnboardingStatusRepository(
        const OnboardingStatusModel(
          accountStatus: RiderAccountStatus.active,
          onboardingStatus: RiderOnboardingStatus.approved,
        ),
      ),
    ));

    await enterOtp(tester);

    expect(find.text('Dashboard destination'), findsOneWidget);
  });
}
