import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/address_screen.dart';
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
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      landmark: landmark,
      city: city,
      state: state,
      pincode: pincode,
      addressLat: addressLat,
      addressLng: addressLng,
    );
    return _profile;
  }

  @override
  Future<PartnerProfileModel> updateEmergencyContact({
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) =>
      throw UnimplementedError();
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
  String? addressLine1,
  String? addressLine2,
  String? landmark,
  String? city,
  String? state,
  String? pincode,
}) =>
    PartnerProfileModel(
      id: 'rider_1',
      name: 'Ravi Kumar',
      phone: '9876543210',
      photoUrl: 'https://cdn.example.com/photo.jpg',
      joinedDate: DateTime(2026, 1, 1),
      dateOfBirth: DateTime(1998, 4, 12),
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      landmark: landmark,
      city: city,
      state: state,
      pincode: pincode,
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
      initialRoute: AppRoutes.address,
      getPages: [
        GetPage(name: AppRoutes.address, page: () => const AddressScreen()),
        GetPage(
          name: AppRoutes.personalInfo,
          page: () => const Scaffold(body: Text('Personal Info Screen')),
        ),
        GetPage(
          name: AppRoutes.vehicleSelection,
          page: () => const Scaffold(body: Text('Vehicle Selection Screen')),
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

  group('addressLine1FromPlacemark', () {
    test('prefers street when present', () {
      const placemark = Placemark(
        street: '221B Baker Street',
        name: 'Some POI',
        subLocality: 'Marylebone',
      );
      expect(addressLine1FromPlacemark(placemark), '221B Baker Street');
    });

    test('falls back to name when street is blank', () {
      const placemark = Placemark(street: '', name: 'Central Park');
      expect(addressLine1FromPlacemark(placemark), 'Central Park');
    });

    test('falls back to subLocality when both street and name are blank', () {
      const placemark = Placemark(subLocality: 'Koramangala');
      expect(addressLine1FromPlacemark(placemark), 'Koramangala');
    });

    test('returns empty string when nothing usable is present', () {
      const placemark = Placemark();
      expect(addressLine1FromPlacemark(placemark), '');
    });
  });

  testWidgets(
      'auto-loads existing address and keeps Save disabled when unchanged',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      addressLine1: '221B Baker Street',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('221B Baker Street'), findsOneWidget);
    expect(find.text('Bengaluru'), findsOneWidget);
    expect(find.text('Karnataka'), findsOneWidget);
    expect(find.text('560001'), findsOneWidget);
    expect(find.text('India'), findsOneWidget);

    final button = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
      'shows a required caption once Address Line 1 is touched and left empty',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile());
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    final line1Field = find.byType(TextField).first;
    await tester.enterText(line1Field, 'x');
    await tester.enterText(line1Field, '');
    await tester.pump();

    expect(find.text('Address Line 1 is required'), findsOneWidget);

    final button = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('invalid PIN code keeps Save disabled and shows an inline error',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      addressLine1: '221B Baker Street',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    final pincodeField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '560001',
    );
    await tester.enterText(pincodeField, '12AB56');
    await tester.pump();

    expect(find.text('Enter a valid 6-digit PIN code'), findsOneWidget);
    final button = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('editing to a valid, dirty address enables Save and saves it',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      addressLine1: '221B Baker Street',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    final line1Field = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '221B Baker Street',
    );
    await tester.enterText(line1Field, '221C Baker Street');
    await tester.pump();

    final button = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 1);
    expect(find.text('Vehicle Selection Screen'), findsOneWidget);
  });

  testWidgets(
      'trims and collapses duplicate spaces before saving (dirty-check ignores whitespace-only edits)',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      addressLine1: '221B Baker Street',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    final line1Field = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '221B Baker Street',
    );
    // Trailing/extra whitespace only — normalizes back to the original,
    // so this should NOT be considered dirty.
    await tester.enterText(line1Field, '221B   Baker Street  ');
    await tester.pump();

    final button = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('a locked (403) section shows a banner and does not navigate',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      addressLine1: '221B Baker Street',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
    ));
    repo.updateError = const ApiException(
      message:
          'Onboarding has already been submitted — this section can no longer be edited.',
      statusCode: 403,
    );
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    final line1Field = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '221B Baker Street',
    );
    await tester.enterText(line1Field, 'Changed Address');
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
      addressLine1: '221B Baker Street',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
    ));
    repo.updateError =
        const ApiException(message: 'Unauthorized', statusCode: 401);
    final authRepo = FakeAuthRepository();
    await tester.pumpWidget(
      buildApp(profileRepository: repo, authRepository: authRepo),
    );
    await tester.pumpAndSettle();

    final line1Field = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '221B Baker Street',
    );
    await tester.enterText(line1Field, 'Changed Address');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(authRepo.loggedOut, isTrue);
    expect(find.text('Welcome Screen'), findsOneWidget);
  });

  testWidgets('a server failure on save shows the message with a Retry action',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      addressLine1: '221B Baker Street',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
    ));
    repo.updateError = const ApiException(
      message:
          'Verification failed due to a server issue. Please try again later.',
      statusCode: 500,
    );
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    final line1Field = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '221B Baker Street',
    );
    await tester.enterText(line1Field, 'Changed Address');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('server issue'), findsWidgets);
    expect(find.text('Retry'), findsWidgets);
    expect(repo.updateCalls, 1);
  });

  testWidgets(
      'an offline failure on save shows a persistent offline banner with Retry',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      addressLine1: '221B Baker Street',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
    ));
    repo.updateError = const ApiException(
      message: 'Unable to connect. Check your internet connection.',
      code: 'connectionError',
    );
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    final line1Field = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '221B Baker Street',
    );
    await tester.enterText(line1Field, 'Changed Address');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining("You're offline"), findsOneWidget);
  });

  testWidgets(
      'an initial load failure shows Retry, which re-fetches successfully',
      (tester) async {
    setTallSurface(tester);
    final repo = FlakyProfileRepository(mockProfile(
      addressLine1: '221B Baker Street',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your address'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('221B Baker Street'), findsOneWidget);
    expect(repo.getProfileCalls, 2);
  });

  testWidgets('back navigation returns to personal info without saving',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      addressLine1: '221B Baker Street',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
    ));
    await tester.pumpWidget(buildApp(profileRepository: repo));
    await tester.pumpAndSettle();

    final line1Field = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '221B Baker Street',
    );
    await tester.enterText(line1Field, 'Changed Address');
    await tester.pump();
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 0);
    expect(find.text('Personal Info Screen'), findsOneWidget);
  });

  testWidgets(
      'navigation after save is backend-driven: an already-active account goes straight to the dashboard',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository(mockProfile(
      addressLine1: '221B Baker Street',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
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

    final line1Field = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '221B Baker Street',
    );
    await tester.enterText(line1Field, 'Changed Address');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
  });
}
