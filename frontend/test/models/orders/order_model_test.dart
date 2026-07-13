import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/orders/order_model.dart';
import 'package:delivery_partner_app/core/utils/currency_formatter.dart';

void main() {
  test('OrderModel.mock has consistent earnings breakdown', () {
    final order = OrderModel.mock();
    expect(order.deliveryFee + order.distancePay + order.incentive,
        closeTo(order.amount, 0.001));
    expect(order.amount, 38.50);
  });

  test('itemsSummary and itemCount derive from items', () {
    final order = OrderModel.mock();
    expect(order.itemCount, 3);
    expect(order.itemsSummary, '1 x Chicken Biryani, 1 x Raita, 1 x Coke');
  });

  test('copyWith updates status and pickedUpAt only', () {
    final order = OrderModel.mock();
    final updated =
        order.copyWith(status: OrderStatus.pickupConfirmed, pickedUpAt: '10:25 AM');
    expect(updated.status, OrderStatus.pickupConfirmed);
    expect(updated.pickedUpAt, '10:25 AM');
    expect(updated.id, order.id);
    expect(updated.amount, order.amount);
  });

  test('rupeesPrecise renders two decimals', () {
    expect(CurrencyFormatter.rupeesPrecise(38.5), '₹38.50');
    expect(CurrencyFormatter.rupeesPrecise(920.5), '₹920.50');
  });
}
