import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/orders/order_model.dart';

/// Simulates a live incoming-order push feed. A real backend later replaces
/// this with a websocket/FCM-backed stream behind the same Stream<OrderModel> shape.
class OrderStreamService {
  Stream<OrderModel> incomingOrders() async* {
    await Future.delayed(const Duration(seconds: 5));
    yield const OrderModel(
      id: 'order_incoming_1',
      restaurantName: 'Green Bowl Cafe',
      customerName: 'Rohan Mehta',
      pickupAddress: '9 Residency Road',
      dropAddress: '21 Church Street',
      status: OrderStatus.incomingRequest,
      amount: 78,
      distanceKm: 2.1,
    );
  }
}

final orderStreamServiceProvider = Provider<OrderStreamService>((ref) => OrderStreamService());
