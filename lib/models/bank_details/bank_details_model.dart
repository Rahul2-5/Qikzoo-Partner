import 'package:equatable/equatable.dart';

/// Bank fields live on the rider's KYC row (`RiderKyc.bankAccountHolderName`
/// etc.) — there is no separate bank-details table/endpoint on the backend.
/// `accountNumberMasked` is all `GET /rider/kyc` ever returns for the
/// account number (e.g. `•••• 4321`); the real number is only ever sent,
/// never read back.
class BankDetailsModel extends Equatable {
  final String accountHolderName;
  final String? accountNumberMasked;
  final String ifsc;
  final String bankName;

  const BankDetailsModel({
    required this.accountHolderName,
    required this.accountNumberMasked,
    required this.ifsc,
    required this.bankName,
  });

  @override
  List<Object?> get props => [accountHolderName, accountNumberMasked, ifsc, bankName];
}
