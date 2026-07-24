import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/bank_details/bank_details_model.dart';

abstract class BankDetailsRepository {
  Future<void> saveBankDetails(BankDetailsModel details);
  Future<BankDetailsModel?> getBankDetails();
}

class MockBankDetailsRepository implements BankDetailsRepository {
  BankDetailsModel? _stored;

  @override
  Future<void> saveBankDetails(BankDetailsModel details) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    _stored = details;
  }

  @override
  Future<BankDetailsModel?> getBankDetails() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return _stored;
  }
}

final bankDetailsRepositoryProvider =
    Provider<BankDetailsRepository>((ref) => MockBankDetailsRepository());
