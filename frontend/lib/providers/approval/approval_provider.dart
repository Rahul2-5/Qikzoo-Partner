import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/approval/approval_repository.dart';
import '../../models/approval/approval_status_model.dart';

final approvalStatusProvider = FutureProvider<ApprovalStatusModel>(
  (ref) => ref.watch(approvalRepositoryProvider).getApprovalStatus(),
);
