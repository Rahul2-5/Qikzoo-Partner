import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/orders/order_model.dart';

abstract class OrdersRepository {
  Future<OrderModel?> getActiveOrder();
  Future<OrderModel> updateOrderStatus(String orderId, OrderStatus status);
  Future<List<OrderModel>> getOrderHistory();
}

class MockOrdersRepository implements OrdersRepository {
  OrderModel? _active;

  @override
  Future<OrderModel?> getActiveOrder() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return _active;
  }

  @override
  Future<OrderModel> updateOrderStatus(String orderId, OrderStatus status) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    _active = (_active ?? _mockOrder(orderId)).copyWith(status: status);
    return _active!;
  }

  @override
  Future<List<OrderModel>> getOrderHistory() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return [_mockOrder('order_1').copyWith(status: OrderStatus.completed)];
  }

  OrderModel _mockOrder(String id) => OrderModel(
        id: id,
        restaurantName: 'Spice Route Kitchen',
        customerName: 'Aditi Sharma',
        pickupAddress: '12 MG Road',
        dropAddress: '45 Park Street',
        status: OrderStatus.incomingRequest,
        amount: 96,
        distanceKm: 3.2,
      );
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) => MockOrdersRepository());
