import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/verification_status/verification_status_repository.dart';
import '../../models/verification_status/verification_step_model.dart';

final verificationStepsProvider = FutureProvider<List<VerificationStepModel>>(
  (ref) => ref.watch(verificationStatusRepositoryProvider).getSteps(),
);
