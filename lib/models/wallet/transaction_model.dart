import 'package:equatable/equatable.dart';

enum TransactionType { credit, debit }

class TransactionModel extends Equatable {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime date;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });

  @override
  List<Object?> get props => [id, type, amount, description, date];
}
