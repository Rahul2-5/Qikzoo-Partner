import '../../models/onboarding_status/onboarding_status_model.dart';
import '../routes/app_routes.dart';

/// Single source of truth for "where does the rider go next" during
/// onboarding. Every onboarding screen must resolve its next destination
/// through this helper after completing its own step, instead of
/// hardcoding the next screen itself — the backend's `GET
/// /rider/onboarding` response ([OnboardingStatusModel]) is the actual
/// source of truth; this only translates that response into a concrete
/// route, so the mapping lives in exactly one place.
class NextOnboardingStepResolver {
  NextOnboardingStepResolver._();

  static String resolve(OnboardingStatusModel status) {
    if (status.isActive) return AppRoutes.dashboard;

    if (!status.isEditable) {
      // SUBMITTED / UNDER_REVIEW / APPROVED (account not yet ACTIVE) /
      // REJECTED without an open clarification — nothing left to edit
      // right now.
      return AppRoutes.verificationStatus;
    }

    return switch (status.currentStep) {
      'PROFILE' => AppRoutes.personalInfo,
      'VEHICLE' => AppRoutes.vehicleSelection,
      // KYC, EMERGENCY_CONTACT and REVIEW don't have a dedicated
      // production screen yet (later onboarding phases) — park the rider
      // on the status screen rather than guessing a destination that
      // doesn't exist. Update this mapping as each phase ships its screen.
      _ => AppRoutes.verificationStatus,
    };
  }
}
