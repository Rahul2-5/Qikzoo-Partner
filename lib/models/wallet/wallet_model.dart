import 'package:equatable/equatable.dart';

class WalletModel extends Equatable {
  final double balance;
  final double pendingAmount;

  const WalletModel({required this.balance, required this.pendingAmount});

  @override
  List<Object?> get props => [balance, pendingAmount];
}
