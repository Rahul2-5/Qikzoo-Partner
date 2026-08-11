import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/approval/approval_status_model.dart';
import '../../models/onboarding_status/onboarding_status_model.dart';
import '../onboarding_status/onboarding_status_repository.dart';

abstract class ApprovalRepository {
  Future<ApprovalStatusModel> getApprovalStatus();
}

/// Reuses [OnboardingStatusRepository] (`GET /rider/onboarding`) — there is
/// no separate approval-status endpoint; `onboardingStatus` on that model
/// already carries this rider's real review state.
class OnboardingApprovalRepository implements ApprovalRepository {
  const OnboardingApprovalRepository({required OnboardingStatusRepository repository})
      : _repository = repository;

  final OnboardingStatusRepository _repository;

  @override
  Future<ApprovalStatusModel> getApprovalStatus() async {
    final status = await _repository.getStatus();
    return ApprovalStatusModel(
      state: _stateFrom(status.onboardingStatus),
      rejectionReason: status.rejectionReason,
    );
  }

  ApprovalState _stateFrom(RiderOnboardingStatus status) => switch (status) {
        RiderOnboardingStatus.notStarted ||
        RiderOnboardingStatus.inProgress =>
          ApprovalState.pending,
        RiderOnboardingStatus.submitted ||
        RiderOnboardingStatus.underReview ||
        RiderOnboardingStatus.clarificationRequired =>
          ApprovalState.underReview,
        RiderOnboardingStatus.approved => ApprovalState.approved,
        RiderOnboardingStatus.rejected => ApprovalState.rejected,
        RiderOnboardingStatus.unknown => ApprovalState.pending,
      };
}

final approvalRepositoryProvider = Provider<ApprovalRepository>(
  (ref) => OnboardingApprovalRepository(
    repository: ref.watch(onboardingStatusRepositoryProvider),
  ),
);
