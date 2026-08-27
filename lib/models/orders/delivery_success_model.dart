import 'package:equatable/equatable.dart';

class DeliverySuccessModel extends Equatable {
  const DeliverySuccessModel({
    required this.orderNumber,
    required this.paymentStatusLabel,
    required this.collectedAmountPaise,
    required this.completedAt,
    required this.riderEarningsPaise,
  });

  final String orderNumber;
  final String paymentStatusLabel;
  final int collectedAmountPaise;
  final DateTime completedAt;
  final int? riderEarningsPaise;

  @override
  List<Object?> get props => [
        orderNumber,
        paymentStatusLabel,
        collectedAmountPaise,
        completedAt,
        riderEarningsPaise,
      ];
}
