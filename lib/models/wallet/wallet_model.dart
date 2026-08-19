import 'package:equatable/equatable.dart';

class WalletModel extends Equatable {
  final double balance;
  final double pendingAmount;
  final double floatingCash;
  final double cashLimit;

  const WalletModel({
    required this.balance,
    required this.pendingAmount,
    this.floatingCash = 0.0,
    this.cashLimit = 2000.0,
  });

  @override
  List<Object?> get props => [balance, pendingAmount, floatingCash, cashLimit];
}
