import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/verification_status_screen.dart';
import 'package:delivery_partner_app/models/onboarding_status/onboarding_status_model.dart';
import 'package:delivery_partner_app/models/partner_registration/personal_info_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/repositories/onboarding_status/onboarding_status_repository.dart';
import 'package:delivery_partner_app/repositories/profile/profile_repository.dart';

class FakeOnboardingStatusRepository implements OnboardingStatusRepository {
  FakeOnboardingStatusRepository({this.status, this.error});
  OnboardingStatusModel? status;
  Object? error;
  int reapplyCalls = 0;
  Object? reapplyError;

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
  Future<void> reapply() async {
    reapplyCalls++;
    if (reapplyError != null) throw reapplyError!;
    status = const OnboardingStatusModel(
      accountStatus: RiderAccountStatus.pendingKyc,
      onboardingStatus: RiderOnboardingStatus.inProgress,
      currentStep: 'PROFILE',
    );
  }
}

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<PartnerProfileModel> getProfile() async => PartnerProfileModel(
        id: 'rider_1',
        name: 'Ravi Kumar',
        phone: '9876543210',
        joinedDate: DateTime(2026, 1, 1),
      );

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

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp(FakeOnboardingStatusRepository repository) {
  return ProviderScope(
    overrides: [
      onboardingStatusRepositoryProvider.overrideWithValue(repository),
      profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.verificationStatus,
      getPages: [
        GetPage(
          name: AppRoutes.verificationStatus,
          page: () => const VerificationStatusScreen(),
        ),
        GetPage(
          name: AppRoutes.personalInfo,
          page: () => const Scaffold(body: Text('Personal Info Screen')),
        ),
        GetPage(
          name: AppRoutes.dashboard,
          page: () => const Scaffold(body: Text('Dashboard Screen')),
        ),
      ],
    ),
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('SUBMITTED shows the under-review message', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp(FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.submitted,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Application under review'), findsOneWidget);
  });

  testWidgets('UNDER_REVIEW shows the same review-in-progress message',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp(FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.underReview,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Application under review'), findsOneWidget);
  });

  testWidgets('APPROVED but not yet ACTIVE shows the approved message',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp(FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.approved,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Application approved'), findsOneWidget);
  });

  testWidgets('REJECTED shows the rejection reason and a Reapply button when allowed',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp(FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.rejected,
        rejectionReason: 'RC document does not match registration number.',
        reapplyAllowed: true,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Application rejected'), findsOneWidget);
    expect(find.textContaining('does not match registration number'),
        findsOneWidget);
    expect(find.text('Reapply'), findsOneWidget);
  });

  testWidgets('REJECTED without reapplyAllowed hides the Reapply button',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp(FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.rejected,
        rejectionReason: 'Documents unclear.',
        reapplyAllowed: false,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Reapply'), findsNothing);
  });

  testWidgets('tapping Reapply resets onboarding and routes back into the flow',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.rejected,
        rejectionReason: 'Documents unclear.',
        reapplyAllowed: true,
      ),
    );
    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reapply'));
    await tester.pumpAndSettle();

    expect(repo.reapplyCalls, 1);
    expect(find.text('Personal Info Screen'), findsOneWidget);
  });

  testWidgets(
      'an already-editable status (e.g. clarification reopened) auto-navigates away',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp(FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.clarificationRequired,
        currentStep: 'PROFILE',
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Personal Info Screen'), findsOneWidget);
  });

  testWidgets('an already-active account auto-navigates to the dashboard',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp(FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.active,
        onboardingStatus: RiderOnboardingStatus.approved,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
  });

  testWidgets('a load failure shows Retry, which succeeds on refresh',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeOnboardingStatusRepository(
      error: const ApiException(
        message: 'Unable to connect. Check your internet connection.',
      ),
    );
    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your status'), findsOneWidget);

    repo.error = null;
    repo.status = const OnboardingStatusModel(
      accountStatus: RiderAccountStatus.pendingKyc,
      onboardingStatus: RiderOnboardingStatus.submitted,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Application under review'), findsOneWidget);
  });
}
