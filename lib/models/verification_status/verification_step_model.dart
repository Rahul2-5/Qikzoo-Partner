import 'package:equatable/equatable.dart';

enum VerificationStepType { identity, vehicle, bank, training, finalApproval }

enum VerificationStepState { pending, inProgress, completed }

class VerificationStepModel extends Equatable {
  final VerificationStepType step;
  final VerificationStepState state;

  const VerificationStepModel({required this.step, required this.state});

  @override
  List<Object?> get props => [step, state];
}
