import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/orders/orders_repository.dart';
import '../../models/orders/order_model.dart';

class ActiveOrderNotifier extends AsyncNotifier<OrderModel?> {
  @override
  Future<OrderModel?> build() => ref.watch(ordersRepositoryProvider).getActiveOrder();

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ordersRepositoryProvider).updateOrderStatus(orderId, status),
    );
  }
}

final activeOrderProvider = AsyncNotifierProvider<ActiveOrderNotifier, OrderModel?>(
  ActiveOrderNotifier.new,
);
