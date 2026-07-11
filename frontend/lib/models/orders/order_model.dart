import 'package:equatable/equatable.dart';

enum OrderStatus {
  waitingForOrders,
  incomingRequest,
  accepted,
  navigatingToRestaurant,
  arrivedAtRestaurant,
  pickupConfirmed,
  navigatingToCustomer,
  arrivedAtCustomer,
  deliveryConfirmed,
  completed,
}

class OrderModel extends Equatable {
  final String id;
  final String restaurantName;
  final String customerName;
  final String pickupAddress;
  final String dropAddress;
  final OrderStatus status;
  final double amount;
  final double distanceKm;

  const OrderModel({
    required this.id,
    required this.restaurantName,
    required this.customerName,
    required this.pickupAddress,
    required this.dropAddress,
    required this.status,
    required this.amount,
    required this.distanceKm,
  });

  OrderModel copyWith({OrderStatus? status}) => OrderModel(
        id: id,
        restaurantName: restaurantName,
        customerName: customerName,
        pickupAddress: pickupAddress,
        dropAddress: dropAddress,
        status: status ?? this.status,
        amount: amount,
        distanceKm: distanceKm,
      );

  @override
  List<Object?> get props =>
      [id, restaurantName, customerName, pickupAddress, dropAddress, status, amount, distanceKm];
}
