import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/verification_status/verification_step_model.dart';

abstract class VerificationStatusRepository {
  Future<List<VerificationStepModel>> getSteps();
}

class MockVerificationStatusRepository implements VerificationStatusRepository {
  @override
  Future<List<VerificationStepModel>> getSteps() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return const [
      VerificationStepModel(step: VerificationStepType.identity, state: VerificationStepState.completed),
      VerificationStepModel(step: VerificationStepType.vehicle, state: VerificationStepState.completed),
      VerificationStepModel(step: VerificationStepType.bank, state: VerificationStepState.inProgress),
      VerificationStepModel(step: VerificationStepType.training, state: VerificationStepState.pending),
      VerificationStepModel(step: VerificationStepType.finalApproval, state: VerificationStepState.pending),
    ];
  }
}

final verificationStatusRepositoryProvider =
    Provider<VerificationStatusRepository>((ref) => MockVerificationStatusRepository());
