import 'package:equatable/equatable.dart';

/// No backend "training" section/step exists — dropped rather than
/// fabricated. `identity` and `bank` both map to the backend's single KYC
/// section (it stores government ID and bank payout details together).
enum VerificationStepType { identity, vehicle, bank, finalApproval }

enum VerificationStepState { pending, inProgress, completed }

class VerificationStepModel extends Equatable {
  final VerificationStepType step;
  final VerificationStepState state;

  const VerificationStepModel({required this.step, required this.state});

  @override
  List<Object?> get props => [step, state];
}
