import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/review_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/kyc/rider_kyc_model.dart';
import 'package:delivery_partner_app/models/onboarding_status/onboarding_status_model.dart';
import 'package:delivery_partner_app/models/partner_registration/personal_info_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/models/vehicle/rider_vehicle_model.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/kyc/kyc_repository.dart';
import 'package:delivery_partner_app/repositories/onboarding_status/onboarding_status_repository.dart';
import 'package:delivery_partner_app/repositories/profile/profile_repository.dart';
import 'package:delivery_partner_app/repositories/vehicle/vehicle_repository.dart';
import 'package:delivery_partner_app/shared/widgets/buttons/primary_cta_button.dart';

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this._profile);
  final PartnerProfileModel _profile;
  int getProfileCalls = 0;

  @override
  Future<PartnerProfileModel> getProfile() async {
    getProfileCalls++;
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

class FakeKycRepository implements KycRepository {
  FakeKycRepository(this._kyc);
  final RiderKycModel? _kyc;

  @override
  Future<RiderKycModel?> getKyc() async => _kyc;

  @override
  Future<RiderKycModel> submit({
    GovernmentIdType? governmentIdType,
    String? governmentIdNumber,
    String? drivingLicenseNumber,
    DateTime? drivingLicenseExpiry,
    String? bankAccountHolderName,
    String? bankAccountNumber,
    String? confirmBankAccountNumber,
    String? bankIfsc,
    String? bankName,
  }) =>
      throw UnimplementedError();

  @override
  Future<RiderKycModel> uploadGovernmentIdDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<RiderKycModel> uploadDrivingLicenseDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();
}

class FakeVehicleRepository implements VehicleRepository {
  FakeVehicleRepository(this._vehicles);
  final List<RiderVehicleModel> _vehicles;

  @override
  Future<List<RiderVehicleModel>> listVehicles() async => _vehicles;

  @override
  Future<RiderVehicleModel> createVehicle({
    required VehicleType type,
    required String registrationNumber,
    String? insuranceNumber,
    DateTime? insuranceExpiry,
    String? rcNumber,
  }) =>
      throw UnimplementedError();

  @override
  Future<RiderVehicleModel> setActive(String vehicleId) =>
      throw UnimplementedError();

  @override
  Future<RiderVehicleModel> uploadRcDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<RiderVehicleModel> uploadInsuranceDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();
}

class FakeOnboardingStatusRepository implements OnboardingStatusRepository {
  FakeOnboardingStatusRepository({required this.status, this.submitError});
  OnboardingStatusModel status;
  Object? submitError;
  int submitCalls = 0;

  @override
  Future<OnboardingStatusModel> getStatus() async => status;

  @override
  Future<void> submitOnboarding({
    required String termsVersion,
    required String privacyPolicyVersion,
  }) async {
    submitCalls++;
    if (submitError != null) throw submitError!;
    status = const OnboardingStatusModel(
      accountStatus: RiderAccountStatus.pendingKyc,
      onboardingStatus: RiderOnboardingStatus.submitted,
    );
  }

  @override
  Future<void> reapply() => throw UnimplementedError();
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

PartnerProfileModel mockProfile() => PartnerProfileModel(
      id: 'rider_1',
      name: 'Ravi Kumar',
      phone: '9876543210',
      joinedDate: DateTime(2026, 1, 1),
      dateOfBirth: DateTime(1998, 4, 12),
      photoUrl: 'https://cdn.example.com/photo.jpg',
      addressLine1: '221B Baker Street',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
      emergencyContactName: 'Sunita Kumar',
      emergencyContactPhone: '9876500000',
    );

final mockKyc = RiderKycModel(
  governmentIdType: GovernmentIdType.aadhaar,
  governmentIdNumber: '123456789012',
  governmentIdDocumentUrl: 'rider-kyc-documents/aadhaar.jpg',
  drivingLicenseNumber: 'DL0420110149646',
  drivingLicenseExpiry: DateTime.now().add(const Duration(days: 365)),
  drivingLicenseDocumentUrl: 'rider-kyc-documents/dl.jpg',
  bankAccountHolderName: 'Ravi Kumar',
  bankAccountNumberMasked: '•••• 9012',
  bankIfsc: 'HDFC0001234',
  bankName: 'HDFC Bank',
);

const mockVehicle = RiderVehicleModel(
  id: 'vehicle_1',
  type: VehicleType.bike,
  registrationNumber: 'KA01AB1234',
  rcDocumentUrl: 'rider-vehicle-documents/rc.jpg',
  insuranceDocumentUrl: 'rider-vehicle-documents/insurance.jpg',
  isActive: true,
);

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp({
  required FakeProfileRepository profileRepository,
  required FakeKycRepository kycRepository,
  required FakeVehicleRepository vehicleRepository,
  required FakeOnboardingStatusRepository onboardingStatusRepository,
  FakeAuthRepository? authRepository,
}) {
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(profileRepository),
      kycRepositoryProvider.overrideWithValue(kycRepository),
      vehicleRepositoryProvider.overrideWithValue(vehicleRepository),
      onboardingStatusRepositoryProvider
          .overrideWithValue(onboardingStatusRepository),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.review,
      getPages: [
        GetPage(name: AppRoutes.review, page: () => const ReviewScreen()),
        GetPage(
          name: AppRoutes.personalInfo,
          page: () => const Scaffold(body: Text('Personal Info Screen')),
        ),
        GetPage(
          name: AppRoutes.verificationStatus,
          page: () => const Scaffold(body: Text('Verification Status Screen')),
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

FakeOnboardingStatusRepository readyStatus() => FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.inProgress,
        currentStep: 'REVIEW',
        isSubmittable: true,
      ),
    );

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('loads and displays every section', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp(
      profileRepository: FakeProfileRepository(mockProfile()),
      kycRepository: FakeKycRepository(mockKyc),
      vehicleRepository: FakeVehicleRepository([mockVehicle]),
      onboardingStatusRepository: readyStatus(),
    ));
    await tester.pumpAndSettle();

    // Each of these section titles also appears as a step label in the
    // OnboardingProgressBar, so more than one match is expected here.
    expect(find.text('Personal Details'), findsWidgets);
    expect(find.text('Address'), findsWidgets);
    expect(find.text('KYC'), findsWidgets);
    expect(find.text('Vehicle'), findsWidgets);
    expect(find.text('Emergency Contact'), findsWidgets);
    expect(find.text('Ravi Kumar'), findsWidgets);
    expect(find.text('Bengaluru'), findsOneWidget);
    expect(find.text('KA01AB1234'), findsOneWidget);
    expect(find.text('Sunita Kumar'), findsOneWidget);
  });

  testWidgets('Submit is disabled until the terms checkbox is checked',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp(
      profileRepository: FakeProfileRepository(mockProfile()),
      kycRepository: FakeKycRepository(mockKyc),
      vehicleRepository: FakeVehicleRepository([mockVehicle]),
      onboardingStatusRepository: readyStatus(),
    ));
    await tester.pumpAndSettle();

    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final updated =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(updated.onPressed, isNotNull);
  });

  testWidgets(
      'Submit stays disabled when the backend reports expired mandatory documents',
      (tester) async {
    setTallSurface(tester);
    final statusRepo = FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.inProgress,
        currentStep: 'REVIEW',
        isSubmittable: false,
        hasExpiredMandatoryDocuments: true,
      ),
    );
    await tester.pumpWidget(buildApp(
      profileRepository: FakeProfileRepository(mockProfile()),
      kycRepository: FakeKycRepository(mockKyc),
      vehicleRepository: FakeVehicleRepository([mockVehicle]),
      onboardingStatusRepository: statusRepo,
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('insurance has expired'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('tapping Edit on a section navigates there and reloads on return',
      (tester) async {
    setTallSurface(tester);
    final profileRepo = FakeProfileRepository(mockProfile());
    await tester.pumpWidget(buildApp(
      profileRepository: profileRepo,
      kycRepository: FakeKycRepository(mockKyc),
      vehicleRepository: FakeVehicleRepository([mockVehicle]),
      onboardingStatusRepository: readyStatus(),
    ));
    await tester.pumpAndSettle();

    final initialCalls = profileRepo.getProfileCalls;
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();

    expect(find.text('Personal Info Screen'), findsOneWidget);

    Get.back();
    await tester.pumpAndSettle();

    expect(find.text('Check everything before sending it for approval'),
        findsOneWidget);
    expect(profileRepo.getProfileCalls, greaterThan(initialCalls));
  });

  testWidgets('submitting successfully navigates to Verification Status',
      (tester) async {
    setTallSurface(tester);
    final statusRepo = readyStatus();
    await tester.pumpWidget(buildApp(
      profileRepository: FakeProfileRepository(mockProfile()),
      kycRepository: FakeKycRepository(mockKyc),
      vehicleRepository: FakeVehicleRepository([mockVehicle]),
      onboardingStatusRepository: statusRepo,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Submit for Review'));
    await tester.pumpAndSettle();

    expect(statusRepo.submitCalls, 1);
    expect(find.text('Verification Status Screen'), findsOneWidget);
  });

  testWidgets('a hard 401 on submit logs the rider out and navigates to welcome',
      (tester) async {
    setTallSurface(tester);
    final statusRepo = readyStatus()
      ..submitError =
          const ApiException(message: 'Unauthorized', statusCode: 401);
    final authRepo = FakeAuthRepository();
    await tester.pumpWidget(buildApp(
      profileRepository: FakeProfileRepository(mockProfile()),
      kycRepository: FakeKycRepository(mockKyc),
      vehicleRepository: FakeVehicleRepository([mockVehicle]),
      onboardingStatusRepository: statusRepo,
      authRepository: authRepo,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Submit for Review'));
    await tester.pumpAndSettle();

    expect(authRepo.loggedOut, isTrue);
    expect(find.text('Welcome Screen'), findsOneWidget);
  });

  testWidgets('an offline failure on submit shows a persistent offline banner',
      (tester) async {
    setTallSurface(tester);
    final statusRepo = readyStatus()
      ..submitError = const ApiException(
        message: 'Unable to connect. Check your internet connection.',
        code: 'connectionError',
      );
    await tester.pumpWidget(buildApp(
      profileRepository: FakeProfileRepository(mockProfile()),
      kycRepository: FakeKycRepository(mockKyc),
      vehicleRepository: FakeVehicleRepository([mockVehicle]),
      onboardingStatusRepository: statusRepo,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Submit for Review'));
    await tester.pumpAndSettle();

    expect(find.textContaining("You're offline"), findsOneWidget);
    expect(statusRepo.submitCalls, 1);
  });

  testWidgets(
      'a server validation failure (400 incomplete) shows the message with Retry',
      (tester) async {
    setTallSurface(tester);
    final statusRepo = readyStatus()
      ..submitError = const ApiException(
        message: 'Onboarding is incomplete.',
        statusCode: 400,
      );
    await tester.pumpWidget(buildApp(
      profileRepository: FakeProfileRepository(mockProfile()),
      kycRepository: FakeKycRepository(mockKyc),
      vehicleRepository: FakeVehicleRepository([mockVehicle]),
      onboardingStatusRepository: statusRepo,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Submit for Review'));
    await tester.pumpAndSettle();

    expect(find.textContaining('incomplete'), findsWidgets);
    expect(find.text('Retry'), findsWidgets);
  });
}
