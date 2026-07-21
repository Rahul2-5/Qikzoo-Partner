import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/orders/order_model.dart';

/// Simulates a live incoming-order push feed. A real backend later replaces
/// this with a websocket/FCM-backed stream behind the same Stream<OrderModel> shape.
class OrderStreamService {
  Stream<OrderModel> incomingOrders() async* {
    await Future.delayed(const Duration(seconds: 5));
    yield const OrderModel(
      id: 'order_incoming_1',
      restaurantName: 'Indigo Bowl Cafe',
      restaurantArea: 'Residency Road',
      customerName: 'Rohan Mehta',
      pickupAddress: '9 Residency Road',
      dropAddress: '21 Church Street',
      dropPincode: '560001',
      status: OrderStatus.incomingRequest,
      amount: 78,
      distanceKm: 2.1,
      pickupDistanceKm: 0.6,
      etaMinutes: 10,
      items: [OrderItem(name: 'Buddha Bowl', quantity: 1)],
      customerNote: null,
      pickedUpAt: null,
      deliveryFee: 60,
      distancePay: 14,
      incentive: 4,
    );
  }
}

final orderStreamServiceProvider =
    Provider<OrderStreamService>((ref) => OrderStreamService());
