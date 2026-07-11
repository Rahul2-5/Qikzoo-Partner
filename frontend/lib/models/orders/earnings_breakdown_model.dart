import 'package:equatable/equatable.dart';

class EarningsBreakdownModel extends Equatable {
  final String orderId;
  final double base;
  final double distance;
  final double surge;
  final double tip;

  const EarningsBreakdownModel({
    required this.orderId,
    required this.base,
    required this.distance,
    required this.surge,
    required this.tip,
  });

  double get total => base + distance + surge + tip;

  @override
  List<Object?> get props => [orderId, base, distance, surge, tip];
}
