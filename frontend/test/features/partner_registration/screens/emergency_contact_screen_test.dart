import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/emergency_contact_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/onboarding_status/onboarding_status_model.dart';
import 'package:delivery_partner_app/models/partner_registration/personal_info_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/onboarding_status/onboarding_status_repository.dart';
import 'package:delivery_partner_app/repositories/profile/profile_repository.dart';
import 'package:delivery_partner_app/shared/widgets/buttons/primary_cta_button.dart';

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this._profile);

  PartnerProfileModel _profile;
  Object? updateError;
  int updateCalls = 0;

  @override
  Future<PartnerProfileModel> getProfile() async => _profile;

  @override
  Future<RatingModel> getRating() async =>
      const RatingModel(average: 0, totalRatings: 0);

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
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
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
  }) async {
    updateCalls++;
    if (updateError != null) throw updateError!;
    _profile = PartnerProfileModel(
      id: _profile.id,
      name: _profile.name,
      phone: _profile.phone,
      photoUrl: _profile.photoUrl,
      joinedDate: _profile.joinedDate,
      email: _profile.email,
      dateOfBirth: _profile.dateOfBirth,
      gender: _profile.gender,
      addressLine1: _profile.addressLine1,
      addressLine2: _profile.addressLine2,
      landmark: _profile.landmark,
      city: _profile.city,
      state: _profile.state,
      pincode: _profile.pincode,
      addressLat: _profile.addressLat,
      addressLng: _profile.addressLng,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
    );
    return _profile;
  }
}

class FlakyProfileRepository implements ProfileRepository {
  FlakyProfileRepository(this._profile);
  final PartnerProfileModel _profile;
  int getProfileCalls = 0;

  @override
  Future<PartnerProfileModel> getProfile() async {
    getProfileCalls++;
    if (getProfileCalls == 1) {
      throw const ApiException(
        message: 'Unable to connect. Check your internet connection.',
      );
    }
    return _profile;
  }

  @override
  Future<RatingModel> getRating() async =>
      const RatingModel(average: 0, totalRatings: 0);

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
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
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

class FakeAuthRepository implements AuthRepository {
  bool loggedOut = false;

  @override
  Future<OtpModel> requestOtp(String phoneNumber) => throw UnimplementedError();

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp,
          {String? name}) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {
    loggedOut = true;
  }
}

class FakeOnboardingStatusRepository implements OnboardingStatusRepository {
  FakeOnboardingStatusRepository({this.status, this.error});
  final OnboardingStatusModel? status;
  final Object? error;

  @override
  Future<OnboardingStatusModel> getStatus() async {
    if (error != null) throw error!;
    return status!;
  }

  @override
  Future<void> submitOnboarding({
    required String termsVersion,
    required String privacyPolicyVersion,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> reapply() => throw UnimplementedError();
}

PartnerProfileModel mockProfile({
  String? emergencyContactName,
  String? emergencyContactPhone,
}) =>
    PartnerProfileModel(
      id: 'rider_1',
      name: 'Ravi Kumar',
      phone: '9876543210',
      joinedDate: DateTime(2026, 1, 1),
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
    );

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp({
  required ProfileRepository profileRepository,
  FakeAuthRepository? authRepository,
  FakeOnboardingStatusRepository? onboardingStatusRepository,
}) {
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(profileRepository),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
      if (onboardingStatusRepository != null)
        onboardingStatusRepositoryProvider
            .overrideWithValue(onboardingStatusRepository),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.emergencyContact,
      getPages: [
        GetPage(
            name: AppRoutes.emergencyContact,
            page: () => const EmergencyContactScreen()),
        GetPage(
          name: AppRoutes.review,
          page: () => const Scaffold(body: Text('Review Screen')),
        ),
        GetPage(
          name: AppRoutes.dashboard,
          page: () => const Scaffold(body: Text('Dashboard Screen')),
        ),
        GetPage(
          name: AppRoutes.welcome,
          page: () => const Scaffold(body: Text('Welcome Screen')),
        ),
      ],
    ),
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets(
      'auto-loads existing emergency contact and keeps Save disabled when unchanged',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      emergencyContactName: 'Sunita Kumar',
      emergencyContactPhone: '9876500000',
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Sunita Kumar'), findsOneWidget);
    expect(find.text('9876500000'), findsOneWidget);

    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows a required caption once the name is touched and left empty',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile());
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    final nameField = find.byType(TextField).first;
    await tester.enterText(nameField, 'x');
    await tester.enterText(nameField, '');
    await tester.pump();

    expect(find.text('Contact name is required'), findsOneWidget);
  });

  testWidgets('an invalid phone number keeps Save disabled with an inline error',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      emergencyContactName: 'Sunita Kumar',
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    final phoneField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '',
    );
    await tester.enterText(phoneField, '12345');
    await tester.pump();

    expect(find.text('Enter a valid 10-digit phone number'), findsOneWidget);
    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNull);
  });

  testWidgets(
      'a phone number matching the rider\'s own number is rejected client-side',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      emergencyContactName: 'Sunita Kumar',
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    final phoneField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '',
    );
    await tester.enterText(phoneField, '9876543210');
    await tester.pump();

    expect(find.text('Cannot be the same as your own number'), findsOneWidget);
  });

  testWidgets('editing to a valid, dirty contact enables Save and saves it',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile());
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Sunita Kumar');
    final phoneField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '',
    );
    await tester.enterText(phoneField, '9876500000');
    await tester.pump();

    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 1);
    expect(find.text('Review Screen'), findsOneWidget);
  });

  testWidgets('a locked (403) section shows a banner and does not navigate',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile())
      ..updateError = const ApiException(
        message:
            'Onboarding has already been submitted — this section can no longer be edited.',
        statusCode: 403,
      );
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Sunita Kumar');
    final phoneField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '',
    );
    await tester.enterText(phoneField, '9876500000');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('can no longer be edited'), findsWidgets);
    expect(find.text('Review Screen'), findsNothing);
  });

  testWidgets('a hard 401 logs the rider out and navigates to welcome',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile())
      ..updateError =
          const ApiException(message: 'Unauthorized', statusCode: 401);
    final authRepo = FakeAuthRepository();
    await tester.pumpWidget(
      buildApp(profileRepository: repo, authRepository: authRepo),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Sunita Kumar');
    final phoneField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '',
    );
    await tester.enterText(phoneField, '9876500000');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(authRepo.loggedOut, isTrue);
    expect(find.text('Welcome Screen'), findsOneWidget);
  });

  testWidgets(
      'an offline failure on save shows a persistent offline banner with Retry',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile())
      ..updateError = const ApiException(
        message: 'Unable to connect. Check your internet connection.',
        code: 'connectionError',
      );
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Sunita Kumar');
    final phoneField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '',
    );
    await tester.enterText(phoneField, '9876500000');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining("You're offline"), findsOneWidget);
  });

  testWidgets('an initial load failure shows Retry, which re-fetches successfully',
      (tester) async {
    setTallSurface(tester);
    final repo = FlakyProfileRepository(mockProfile(
      emergencyContactName: 'Sunita Kumar',
      emergencyContactPhone: '9876500000',
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your emergency contact'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Sunita Kumar'), findsOneWidget);
    expect(repo.getProfileCalls, 2);
  });

  testWidgets('back navigation pops without saving anything', (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile());
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Changed Name');
    await tester.pump();
    Get.back();
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 0);
  });

  testWidgets(
      'navigation after save is backend-driven: an already-active account goes straight to the dashboard',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile());
    final onboardingStatusRepo = FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.active,
        onboardingStatus: RiderOnboardingStatus.approved,
      ),
    );
    await tester.pumpWidget(buildApp(
      profileRepository: repo,
      onboardingStatusRepository: onboardingStatusRepo,
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Sunita Kumar');
    final phoneField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '',
    );
    await tester.enterText(phoneField, '9876500000');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
  });
}
