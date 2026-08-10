import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/onboarding_status/onboarding_status_model.dart';
import '../../models/verification_status/verification_step_model.dart';
import '../onboarding_status/onboarding_status_repository.dart';

abstract class VerificationStatusRepository {
  Future<List<VerificationStepModel>> getSteps();
}

/// Derives per-step state from [OnboardingStatusRepository]
/// (`GET /rider/onboarding`'s `completedSections`/`onboardingStatus`) —
/// there is no separate step-tracking endpoint, and no backend concept of
/// rider "training" at all (dropped, not fabricated as always-pending).
class OnboardingVerificationStatusRepository implements VerificationStatusRepository {
  const OnboardingVerificationStatusRepository({
    required OnboardingStatusRepository repository,
  }) : _repository = repository;

  final OnboardingStatusRepository _repository;

  @override
  Future<List<VerificationStepModel>> getSteps() async {
    final status = await _repository.getStatus();
    final kycDone = status.completedSections.contains('KYC');
    final vehicleDone = status.completedSections.contains('VEHICLE');
    final approved = status.onboardingStatus == RiderOnboardingStatus.approved;

    return [
      VerificationStepModel(
        step: VerificationStepType.identity,
        state: kycDone ? VerificationStepState.completed : VerificationStepState.pending,
      ),
      VerificationStepModel(
        step: VerificationStepType.vehicle,
        state: vehicleDone ? VerificationStepState.completed : VerificationStepState.pending,
      ),
      VerificationStepModel(
        step: VerificationStepType.bank,
        state: kycDone ? VerificationStepState.completed : VerificationStepState.pending,
      ),
      VerificationStepModel(
        step: VerificationStepType.finalApproval,
        state: approved ? VerificationStepState.completed : VerificationStepState.pending,
      ),
    ];
  }
}

final verificationStatusRepositoryProvider = Provider<VerificationStatusRepository>(
  (ref) => OnboardingVerificationStatusRepository(
    repository: ref.watch(onboardingStatusRepositoryProvider),
  ),
);
