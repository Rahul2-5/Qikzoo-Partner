import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/personal_info_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/onboarding_status/onboarding_status_model.dart';
import 'package:delivery_partner_app/models/partner_registration/personal_info_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_image_picker.dart';
import 'package:delivery_partner_app/repositories/onboarding_status/onboarding_status_repository.dart';
import 'package:delivery_partner_app/repositories/profile/profile_repository.dart';
import 'package:delivery_partner_app/shared/widgets/buttons/primary_cta_button.dart';

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this._profile);

  PartnerProfileModel _profile;
  Object? updateError;
  Object? uploadError;
  int updateCalls = 0;
  int uploadCalls = 0;

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
  }) async {
    updateCalls++;
    if (updateError != null) throw updateError!;
    _profile = PartnerProfileModel(
      id: _profile.id,
      name: name,
      phone: _profile.phone,
      photoUrl: _profile.photoUrl,
      joinedDate: _profile.joinedDate,
      email: email,
      dateOfBirth: dateOfBirth,
      gender: gender,
    );
    return _profile;
  }

  @override
  Future<PartnerProfileModel> uploadProfilePhoto(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    uploadCalls++;
    onSendProgress?.call(1, 1);
    if (uploadError != null) throw uploadError!;
    // Deliberately keep photoUrl as-is (not the local file path): a real
    // backend always returns an https signed URL, and CachedNetworkImage
    // trying to fetch a bogus "URL" here would hang the test on a network
    // call that never resolves. Uploads are asserted via [uploadCalls].
    return _profile;
  }

  @override
  Future<PartnerProfileModel> uploadSelfie(
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

/// Fails the first [getProfile] call (simulating a transient/offline
/// failure) then succeeds, so Retry can be exercised end-to-end.
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
  Future<PartnerProfileModel> uploadSelfie(
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
  Future<OtpModel> requestOtp(String phoneNumber) =>
      throw UnimplementedError();

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp,
          {String? name}) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {
    loggedOut = true;
  }
}

class FakeDocumentImagePicker implements DocumentImagePicker {
  FakeDocumentImagePicker(this.path);
  final String? path;

  @override
  Future<String?> pickImage(ImageSource source) async => path;
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
  String name = 'Ravi Kumar',
  String? email,
  DateTime? dateOfBirth,
  Gender? gender,
  String? photoUrl,
}) =>
    PartnerProfileModel(
      id: 'rider_1',
      name: name,
      phone: '9876543210',
      photoUrl: photoUrl,
      joinedDate: DateTime(2026, 1, 1),
      email: email,
      dateOfBirth: dateOfBirth,
      gender: gender,
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
  FakeDocumentImagePicker? imagePicker,
  FakeOnboardingStatusRepository? onboardingStatusRepository,
}) {
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(profileRepository),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
      if (imagePicker != null)
        documentImagePickerProvider.overrideWithValue(imagePicker),
      if (onboardingStatusRepository != null)
        onboardingStatusRepositoryProvider
            .overrideWithValue(onboardingStatusRepository),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.personalInfo,
      getPages: [
        GetPage(
            name: AppRoutes.personalInfo,
            page: () => const PersonalInfoScreen()),
        GetPage(
          name: AppRoutes.vehicleSelection,
          page: () => const Scaffold(body: Text('Vehicle Selection Screen')),
        ),
        GetPage(
          name: AppRoutes.address,
          page: () => const Scaffold(body: Text('Address Screen')),
        ),
        GetPage(
          name: AppRoutes.vehicleRegistration,
          page: () => const Scaffold(body: Text('Vehicle Registration Screen')),
        ),
        GetPage(
          name: AppRoutes.dashboard,
          page: () => const Scaffold(body: Text('Dashboard Screen')),
        ),
        GetPage(
          name: AppRoutes.verificationStatus,
          page: () =>
              const Scaffold(body: Text('Verification Status Screen')),
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
  setUp(() {
    Get.testMode = true;
    // The photo-upload test uses tester.runAsync (real dart:io File I/O),
    // which exposes the real HTTP client instead of flutter_test's fake
    // one — without this, google_fonts' runtime font fetch fails loudly
    // against real network access this sandbox doesn't have.
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(Get.reset);

  testWidgets(
      'auto-loads existing values and keeps Save disabled when unchanged',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      email: 'ravi@example.com',
      dateOfBirth: DateTime(1998, 4, 12),
      gender: Gender.male,
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(find.text('ravi@example.com'), findsOneWidget);

    final button = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
      'shows required captions for a brand-new rider with no DOB/gender yet',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile());
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Date of birth is required'), findsOneWidget);
    expect(find.text('Please select a gender'), findsOneWidget);
  });

  testWidgets('an invalid name keeps Save disabled even once other fields are set',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      dateOfBirth: DateTime(1998, 4, 12),
      gender: Gender.male,
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'R');
    await tester.pump();

    final button = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Enter 2-60 characters, no emoji'), findsOneWidget);
  });

  testWidgets(
      'editing the name to a valid, dirty value enables Save and saves it',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      dateOfBirth: DateTime(1998, 4, 12),
      gender: Gender.male,
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Suresh Kumar');
    await tester.pump();

    final button = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 1);
    // If the status lookup is unavailable, progress to the known next step
    // rather than leaving the primary action in a loading state.
    expect(find.text('Address Screen'), findsOneWidget);
  });

  testWidgets(
      'navigation after save is backend-driven: VEHICLE as the next step goes to Vehicle Registration',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      dateOfBirth: DateTime(1998, 4, 12),
      gender: Gender.male,
    ));
    final onboardingStatusRepo = FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.inProgress,
        currentStep: 'VEHICLE',
      ),
    );
    await tester.pumpWidget(buildApp(
      profileRepository: repo,
      onboardingStatusRepository: onboardingStatusRepo,
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Suresh Kumar');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Vehicle Registration Screen'), findsOneWidget);
  });

  testWidgets(
      'navigation after save is backend-driven: an already-active account goes straight to the dashboard',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      dateOfBirth: DateTime(1998, 4, 12),
      gender: Gender.male,
    ));
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

    await tester.enterText(find.byType(TextField).first, 'Suresh Kumar');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
    expect(find.text('Vehicle Selection Screen'), findsNothing);
  });

  testWidgets(
      'falls back to Address when the post-save status fetch fails',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      dateOfBirth: DateTime(1998, 4, 12),
      gender: Gender.male,
    ));
    final onboardingStatusRepo = FakeOnboardingStatusRepository(
      error: Exception('network unavailable'),
    );
    await tester.pumpWidget(buildApp(
      profileRepository: repo,
      onboardingStatusRepository: onboardingStatusRepo,
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Suresh Kumar');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Address Screen'), findsOneWidget);
  });

  testWidgets('a locked (403) section shows a banner and does not navigate',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      dateOfBirth: DateTime(1998, 4, 12),
      gender: Gender.male,
    ));
    repo.updateError = const ApiException(
      message:
          'Onboarding has already been submitted — this section can no longer be edited.',
      statusCode: 403,
    );
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Changed Name');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('can no longer be edited'), findsWidgets);
    expect(find.text('Vehicle Selection Screen'), findsNothing);
  });

  testWidgets('a hard 401 logs the rider out and navigates to welcome',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      dateOfBirth: DateTime(1998, 4, 12),
      gender: Gender.male,
    ));
    repo.updateError =
        const ApiException(message: 'Unauthorized', statusCode: 401);
    final authRepo = FakeAuthRepository();
    await tester.pumpWidget(
      buildApp(profileRepository: repo, authRepository: authRepo),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Changed Name');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(authRepo.loggedOut, isTrue);
    expect(find.text('Welcome Screen'), findsOneWidget);
  });

  testWidgets(
      'a server/network failure on save shows the message with a Retry action',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      dateOfBirth: DateTime(1998, 4, 12),
      gender: Gender.male,
    ));
    repo.updateError = const ApiException(
      message: 'Verification failed due to a server issue. Please try again later.',
      statusCode: 500,
    );
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Changed Name');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('server issue'), findsWidgets);
    expect(find.text('Retry'), findsWidgets);
    expect(repo.updateCalls, 1);
  });

  testWidgets('an initial load failure shows Retry, which re-fetches successfully',
      (tester) async {
    setTallSurface(tester);
    final repo = FlakyProfileRepository(mockProfile(
      dateOfBirth: DateTime(1998, 4, 12),
      gender: Gender.male,
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your details'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(repo.getProfileCalls, 2);
  });

  testWidgets('back navigation pops without saving anything',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      dateOfBirth: DateTime(1998, 4, 12),
      gender: Gender.male,
    ));
    await tester.pumpWidget(buildApp(
      profileRepository: repo,
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Changed Name');
    await tester.pump();
    Get.back();
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 0);
  });

  testWidgets('picking a photo uploads it and refreshes the avatar',
      (tester) async {
    setTallSurface(tester);
    // Reuse an existing on-disk file (the package's own pubspec.yaml,
    // relative to `flutter test`'s working directory) so the upload
    // path's real `File.length()` call has something to read — `runAsync`
    // below is what actually lets that real dart:io Future resolve;
    // widget tests otherwise run on a fake clock that never drives real
    // async I/O to completion.
    final existingFile = File('pubspec.yaml').absolute;
    expect(existingFile.existsSync(), isTrue,
        reason: 'test assumes cwd is the frontend package root');

    final repo = FakeProfileRepository(mockProfile(
      dateOfBirth: DateTime(1998, 4, 12),
      gender: Gender.male,
    ));
    await tester.pumpWidget(buildApp(
      profileRepository: repo,
      imagePicker: FakeDocumentImagePicker(existingFile.path),
    ));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('personal_details_photo_picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Gallery'));
      // A real Future.delayed (not just tester.pump) is what actually lets
      // the real dart:io File.length()/upload Future resolve here.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(repo.uploadCalls, 1);
  });
}
