import 'package:delivery_partner_app/core/navigation/next_onboarding_step_resolver.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/models/onboarding_status/onboarding_status_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

OnboardingStatusModel status({
  required RiderAccountStatus accountStatus,
  required RiderOnboardingStatus onboardingStatus,
  String? currentStep,
}) =>
    OnboardingStatusModel(
      accountStatus: accountStatus,
      onboardingStatus: onboardingStatus,
      currentStep: currentStep,
    );

PartnerProfileModel profile({
  String name = '',
  DateTime? dateOfBirth,
  String? photoUrl,
  String? addressLine1,
  String? city,
  String? state,
  String? pincode,
}) =>
    PartnerProfileModel(
      id: 'rider_1',
      name: name,
      phone: '9876543210',
      joinedDate: DateTime(2026, 1, 1),
      dateOfBirth: dateOfBirth,
      photoUrl: photoUrl,
      addressLine1: addressLine1,
      city: city,
      state: state,
      pincode: pincode,
    );

final emptyProfile = profile();

final personalDetailsCompleteProfile = profile(
  name: 'Ravi Kumar',
  dateOfBirth: DateTime(1998, 4, 12),
  photoUrl: 'https://cdn.example.com/photo.jpg',
);

final fullyCompleteProfile = profile(
  name: 'Ravi Kumar',
  dateOfBirth: DateTime(1998, 4, 12),
  photoUrl: 'https://cdn.example.com/photo.jpg',
  addressLine1: '221B Baker Street',
  city: 'Bengaluru',
  state: 'Karnataka',
  pincode: '560001',
);

void main() {
  group('NextOnboardingStepResolver', () {
    test('an active account always goes to the dashboard, regardless of currentStep', () {
      final result = NextOnboardingStepResolver.resolve(
        status(
          accountStatus: RiderAccountStatus.active,
          onboardingStatus: RiderOnboardingStatus.approved,
          currentStep: 'REVIEW',
        ),
        profile: fullyCompleteProfile,
      );

      expect(result, AppRoutes.dashboard);
    });

    test('PROFILE with no personal details yet resolves to Personal Details', () {
      final result = NextOnboardingStepResolver.resolve(
        status(
          accountStatus: RiderAccountStatus.pendingKyc,
          onboardingStatus: RiderOnboardingStatus.inProgress,
          currentStep: 'PROFILE',
        ),
        profile: emptyProfile,
      );

      expect(result, AppRoutes.personalInfo);
    });

    test(
        'PROFILE with personal details already complete but address still missing '
        'resolves to Address, not back to Personal Details',
        () {
      final result = NextOnboardingStepResolver.resolve(
        status(
          accountStatus: RiderAccountStatus.pendingKyc,
          onboardingStatus: RiderOnboardingStatus.inProgress,
          currentStep: 'PROFILE',
        ),
        profile: personalDetailsCompleteProfile,
      );

      expect(result, AppRoutes.address);
    });

    test('KYC as the current step resolves to the KYC screen', () {
      final result = NextOnboardingStepResolver.resolve(
        status(
          accountStatus: RiderAccountStatus.pendingKyc,
          onboardingStatus: RiderOnboardingStatus.inProgress,
          currentStep: 'KYC',
        ),
        profile: fullyCompleteProfile,
      );

      expect(result, AppRoutes.kyc);
    });

    test('VEHICLE as the current step resolves to Vehicle Registration', () {
      final result = NextOnboardingStepResolver.resolve(
        status(
          accountStatus: RiderAccountStatus.pendingKyc,
          onboardingStatus: RiderOnboardingStatus.inProgress,
          currentStep: 'VEHICLE',
        ),
        profile: fullyCompleteProfile,
      );

      expect(result, AppRoutes.vehicleRegistration);
    });

    test('EMERGENCY_CONTACT as the current step resolves to the Emergency Contact screen', () {
      final result = NextOnboardingStepResolver.resolve(
        status(
          accountStatus: RiderAccountStatus.pendingKyc,
          onboardingStatus: RiderOnboardingStatus.inProgress,
          currentStep: 'EMERGENCY_CONTACT',
        ),
        profile: fullyCompleteProfile,
      );

      expect(result, AppRoutes.emergencyContact);
    });

    test('REVIEW as the current step resolves to the Review screen', () {
      final result = NextOnboardingStepResolver.resolve(
        status(
          accountStatus: RiderAccountStatus.pendingKyc,
          onboardingStatus: RiderOnboardingStatus.inProgress,
          currentStep: 'REVIEW',
        ),
        profile: fullyCompleteProfile,
      );

      expect(result, AppRoutes.review);
    });

    test('NOT_STARTED with no currentStep falls back to the status screen', () {
      final result = NextOnboardingStepResolver.resolve(
        status(
          accountStatus: RiderAccountStatus.pendingKyc,
          onboardingStatus: RiderOnboardingStatus.notStarted,
          currentStep: null,
        ),
        profile: emptyProfile,
      );

      expect(result, AppRoutes.verificationStatus);
    });

    for (final step in ['SOMETHING_UNKNOWN']) {
      test('$step has no dedicated screen yet, so it falls back to the status screen', () {
        final result = NextOnboardingStepResolver.resolve(
          status(
            accountStatus: RiderAccountStatus.pendingKyc,
            onboardingStatus: RiderOnboardingStatus.inProgress,
            currentStep: step,
          ),
          profile: fullyCompleteProfile,
        );

        expect(result, AppRoutes.verificationStatus);
      });
    }

    test('CLARIFICATION_REQUIRED is still editable and resolves by currentStep', () {
      final result = NextOnboardingStepResolver.resolve(
        status(
          accountStatus: RiderAccountStatus.pendingKyc,
          onboardingStatus: RiderOnboardingStatus.clarificationRequired,
          currentStep: 'PROFILE',
        ),
        profile: emptyProfile,
      );

      expect(result, AppRoutes.personalInfo);
    });

    for (final terminal in [
      RiderOnboardingStatus.submitted,
      RiderOnboardingStatus.underReview,
      RiderOnboardingStatus.approved,
      RiderOnboardingStatus.rejected,
    ]) {
      test('$terminal (account still not ACTIVE) locks the form to the status screen', () {
        final result = NextOnboardingStepResolver.resolve(
          status(
            accountStatus: RiderAccountStatus.pendingKyc,
            onboardingStatus: terminal,
            currentStep: 'PROFILE',
          ),
          profile: emptyProfile,
        );

        expect(result, AppRoutes.verificationStatus);
      });
    }
  });
}
