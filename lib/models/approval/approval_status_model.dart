import 'package:equatable/equatable.dart';

enum ApprovalState { pending, underReview, approved, rejected }

class ApprovalStatusModel extends Equatable {
  final ApprovalState state;
  final String? rejectionReason;

  const ApprovalStatusModel({required this.state, this.rejectionReason});

  @override
  List<Object?> get props => [state, rejectionReason];
}
