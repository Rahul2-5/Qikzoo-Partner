import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/approval/approval_status_model.dart';

abstract class ApprovalRepository {
  Future<ApprovalStatusModel> getApprovalStatus();
}

class MockApprovalRepository implements ApprovalRepository {
  @override
  Future<ApprovalStatusModel> getApprovalStatus() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return const ApprovalStatusModel(state: ApprovalState.underReview);
  }
}

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) => MockApprovalRepository());
