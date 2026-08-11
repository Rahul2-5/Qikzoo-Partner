import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bank_details/bank_details_model.dart';
import '../kyc/kyc_repository.dart';

abstract class BankDetailsRepository {
  Future<void> saveBankDetails(BankDetailsModel details, {required String accountNumber});
  Future<BankDetailsModel?> getBankDetails();
}

/// Bank details are part of the rider's KYC row — there is no separate
/// bank-details table/endpoint. Reuses [KycRepository] (`GET`/`PUT
/// /rider/kyc`) rather than a second API surface.
class KycBankDetailsRepository implements BankDetailsRepository {
  const KycBankDetailsRepository({required KycRepository kycRepository})
      : _kyc = kycRepository;

  final KycRepository _kyc;

  @override
  Future<void> saveBankDetails(
    BankDetailsModel details, {
    required String accountNumber,
  }) async {
    await _kyc.submit(
      bankAccountHolderName: details.accountHolderName,
      bankAccountNumber: accountNumber,
      confirmBankAccountNumber: accountNumber,
      bankIfsc: details.ifsc,
      bankName: details.bankName,
    );
  }

  @override
  Future<BankDetailsModel?> getBankDetails() async {
    final kyc = await _kyc.getKyc();
    if (kyc == null || !kyc.hasBankAccountOnFile) return null;
    return BankDetailsModel(
      accountHolderName: kyc.bankAccountHolderName ?? '',
      accountNumberMasked: kyc.bankAccountNumberMasked,
      ifsc: kyc.bankIfsc ?? '',
      bankName: kyc.bankName ?? '',
    );
  }
}

final bankDetailsRepositoryProvider = Provider<BankDetailsRepository>(
  (ref) => KycBankDetailsRepository(kycRepository: ref.watch(kycRepositoryProvider)),
);
