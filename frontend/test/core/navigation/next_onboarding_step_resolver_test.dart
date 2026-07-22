import 'package:delivery_partner_app/core/navigation/next_onboarding_step_resolver.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/models/onboarding_status/onboarding_status_model.dart';
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

void main() {
  group('NextOnboardingStepResolver', () {
    test('an active account always goes to the dashboard, regardless of currentStep', () {
      final result = NextOnboardingStepResolver.resolve(status(
        accountStatus: RiderAccountStatus.active,
        onboardingStatus: RiderOnboardingStatus.approved,
        currentStep: 'REVIEW',
      ));

      expect(result, AppRoutes.dashboard);
    });

    test('PROFILE as the current step resolves to Personal Details', () {
      final result = NextOnboardingStepResolver.resolve(status(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.inProgress,
        currentStep: 'PROFILE',
      ));

      expect(result, AppRoutes.personalInfo);
    });

    test('VEHICLE as the current step resolves to Vehicle Selection', () {
      final result = NextOnboardingStepResolver.resolve(status(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.inProgress,
        currentStep: 'VEHICLE',
      ));

      expect(result, AppRoutes.vehicleSelection);
    });

    test('NOT_STARTED with no currentStep falls back to the status screen', () {
      final result = NextOnboardingStepResolver.resolve(status(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.notStarted,
        currentStep: null,
      ));

      expect(result, AppRoutes.verificationStatus);
    });

    for (final step in ['KYC', 'EMERGENCY_CONTACT', 'REVIEW', 'SOMETHING_UNKNOWN']) {
      test('$step has no dedicated screen yet, so it falls back to the status screen', () {
        final result = NextOnboardingStepResolver.resolve(status(
          accountStatus: RiderAccountStatus.pendingKyc,
          onboardingStatus: RiderOnboardingStatus.inProgress,
          currentStep: step,
        ));

        expect(result, AppRoutes.verificationStatus);
      });
    }

    test('CLARIFICATION_REQUIRED is still editable and resolves by currentStep', () {
      final result = NextOnboardingStepResolver.resolve(status(
        accountStatus: RiderAccountStatus.pendingKyc,
        onboardingStatus: RiderOnboardingStatus.clarificationRequired,
        currentStep: 'PROFILE',
      ));

      expect(result, AppRoutes.personalInfo);
    });

    for (final terminal in [
      RiderOnboardingStatus.submitted,
      RiderOnboardingStatus.underReview,
      RiderOnboardingStatus.approved,
      RiderOnboardingStatus.rejected,
    ]) {
      test('$terminal (account still not ACTIVE) locks the form to the status screen', () {
        final result = NextOnboardingStepResolver.resolve(status(
          accountStatus: RiderAccountStatus.pendingKyc,
          onboardingStatus: terminal,
          currentStep: 'PROFILE',
        ));

        expect(result, AppRoutes.verificationStatus);
      });
    }
  });
}
