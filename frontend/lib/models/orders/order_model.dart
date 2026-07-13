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

class OrderItem extends Equatable {
  final String name;
  final int quantity;

  const OrderItem({required this.name, required this.quantity});

  @override
  List<Object?> get props => [name, quantity];
}

class OrderModel extends Equatable {
  final String id;
  final String restaurantName;
  final String restaurantArea;
  final String customerName;
  final String pickupAddress;
  final String dropAddress;
  final String dropPincode;
  final OrderStatus status;
  final double amount;
  final double distanceKm;
  final double pickupDistanceKm;
  final int etaMinutes;
  final List<OrderItem> items;
  final String? customerNote;
  final String? pickedUpAt;
  final double deliveryFee;
  final double distancePay;
  final double incentive;

  const OrderModel({
    required this.id,
    required this.restaurantName,
    required this.restaurantArea,
    required this.customerName,
    required this.pickupAddress,
    required this.dropAddress,
    required this.dropPincode,
    required this.status,
    required this.amount,
    required this.distanceKm,
    required this.pickupDistanceKm,
    required this.etaMinutes,
    required this.items,
    required this.customerNote,
    required this.pickedUpAt,
    required this.deliveryFee,
    required this.distancePay,
    required this.incentive,
  });

  factory OrderModel.mock() => const OrderModel(
        id: '#171287364912',
        restaurantName: 'The Biryani House',
        restaurantArea: 'Goregaon West, Mumbai',
        customerName: 'Rahul Sharma',
        pickupAddress: 'Goregaon West, Mumbai',
        dropAddress: 'Sundervan Complex, Andheri West, Mumbai, Maharashtra',
        dropPincode: '400058',
        status: OrderStatus.incomingRequest,
        amount: 38.50,
        distanceKm: 4.2,
        pickupDistanceKm: 0.8,
        etaMinutes: 12,
        items: [
          OrderItem(name: 'Chicken Biryani', quantity: 1),
          OrderItem(name: 'Raita', quantity: 1),
          OrderItem(name: 'Coke', quantity: 1),
        ],
        customerNote: 'Please send extra tissues',
        pickedUpAt: null,
        deliveryFee: 30.00,
        distancePay: 6.50,
        incentive: 2.00,
      );

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get itemsSummary =>
      items.map((i) => '${i.quantity} x ${i.name}').join(', ');

  OrderModel copyWith({OrderStatus? status, String? pickedUpAt}) => OrderModel(
        id: id,
        restaurantName: restaurantName,
        restaurantArea: restaurantArea,
        customerName: customerName,
        pickupAddress: pickupAddress,
        dropAddress: dropAddress,
        dropPincode: dropPincode,
        status: status ?? this.status,
        amount: amount,
        distanceKm: distanceKm,
        pickupDistanceKm: pickupDistanceKm,
        etaMinutes: etaMinutes,
        items: items,
        customerNote: customerNote,
        pickedUpAt: pickedUpAt ?? this.pickedUpAt,
        deliveryFee: deliveryFee,
        distancePay: distancePay,
        incentive: incentive,
      );

  @override
  List<Object?> get props => [
        id,
        restaurantName,
        restaurantArea,
        customerName,
        pickupAddress,
        dropAddress,
        dropPincode,
        status,
        amount,
        distanceKm,
        pickupDistanceKm,
        etaMinutes,
        items,
        customerNote,
        pickedUpAt,
        deliveryFee,
        distancePay,
        incentive,
      ];
}
