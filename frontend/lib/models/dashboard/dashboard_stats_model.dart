import 'package:equatable/equatable.dart';

class DashboardStatsModel extends Equatable {
  final bool isOnline;
  final double todaysEarnings;
  final double walletBalance;
  final int activeIncentives;
  final double acceptanceRate;
  final double rating;
  final int completedOrders;

  const DashboardStatsModel({
    required this.isOnline,
    required this.todaysEarnings,
    required this.walletBalance,
    required this.activeIncentives,
    required this.acceptanceRate,
    required this.rating,
    required this.completedOrders,
  });

  DashboardStatsModel copyWith({bool? isOnline}) => DashboardStatsModel(
        isOnline: isOnline ?? this.isOnline,
        todaysEarnings: todaysEarnings,
        walletBalance: walletBalance,
        activeIncentives: activeIncentives,
        acceptanceRate: acceptanceRate,
        rating: rating,
        completedOrders: completedOrders,
      );

  @override
  List<Object?> get props => [
        isOnline,
        todaysEarnings,
        walletBalance,
        activeIncentives,
        acceptanceRate,
        rating,
        completedOrders,
      ];
}
