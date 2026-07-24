import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/orders/rider_order_model.dart';
import '../../repositories/orders/rider_orders_repository.dart';

/// `GET /rider/orders/:id` for a specific order, keyed by riderOrderId —
/// used by the read-only Order Details screen (reached from history), the
/// one place the full status timeline is actually shown.
class OrderDetailNotifier extends FamilyAsyncNotifier<RiderOrderModel, String> {
  @override
  Future<RiderOrderModel> build(String arg) =>
      ref.read(riderOrdersRepositoryProvider).getOne(arg);

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(riderOrdersRepositoryProvider).getOne(arg),
    );
  }
}

final orderDetailProvider = AsyncNotifierProvider.family<OrderDetailNotifier,
    RiderOrderModel, String>(OrderDetailNotifier.new);
