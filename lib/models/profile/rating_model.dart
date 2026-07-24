import 'package:equatable/equatable.dart';

class RatingModel extends Equatable {
  final double average;
  final int totalRatings;

  const RatingModel({required this.average, required this.totalRatings});

  @override
  List<Object?> get props => [average, totalRatings];
}
