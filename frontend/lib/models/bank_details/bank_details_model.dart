import 'package:equatable/equatable.dart';

class BankDetailsModel extends Equatable {
  final String accountHolderName;
  final String accountNumber;
  final String ifsc;
  final String? upiId;

  const BankDetailsModel({
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifsc,
    this.upiId,
  });

  @override
  List<Object?> get props => [accountHolderName, accountNumber, ifsc, upiId];
}
