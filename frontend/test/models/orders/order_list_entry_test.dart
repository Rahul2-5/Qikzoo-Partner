import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/orders/order_list_entry.dart';

void main() {
  final all = OrderListEntry.mockList();

  test('mockList covers every status', () {
    expect(all.any((e) => e.status == OrderListStatus.upcoming), isTrue);
    expect(all.any((e) => e.status == OrderListStatus.completed), isTrue);
    expect(all.any((e) => e.status == OrderListStatus.cancelled), isTrue);
  });

  test('OrdersTab.matches filters by status', () {
    final e = all.firstWhere((x) => x.status == OrderListStatus.cancelled);
    expect(OrdersTab.all.matches(e), isTrue);
    expect(OrdersTab.cancelled.matches(e), isTrue);
    expect(OrdersTab.completed.matches(e), isFalse);
  });

  test('filterEntries narrows by tab', () {
    final completed = filterEntries(
        all: all,
        tab: OrdersTab.completed,
        query: '',
        dateFilter: OrdersDateFilter.all);
    expect(completed, isNotEmpty);
    expect(completed.every((e) => e.status == OrderListStatus.completed), isTrue);
  });

  test('filterEntries matches restaurant and id case-insensitively', () {
    final byName = filterEntries(
        all: all,
        tab: OrdersTab.all,
        query: 'burger',
        dateFilter: OrdersDateFilter.all);
    expect(byName.length, 1);
    expect(byName.single.restaurantName, 'Burger Point');

    final byId = filterEntries(
        all: all,
        tab: OrdersTab.all,
        query: '171287364912',
        dateFilter: OrdersDateFilter.all);
    expect(byId.length, 1);
  });

  test('filterEntries today keeps only today entries', () {
    final today = filterEntries(
        all: all,
        tab: OrdersTab.all,
        query: '',
        dateFilter: OrdersDateFilter.today);
    expect(today.every((e) => e.dateGroup.startsWith('Today')), isTrue);
    expect(today.length, lessThan(all.length));
  });

  test('sortEntries highestEarning orders by amount desc', () {
    final sorted = sortEntries(all, OrdersSort.highestEarning);
    for (var i = 1; i < sorted.length; i++) {
      expect(sorted[i - 1].amount, greaterThanOrEqualTo(sorted[i].amount));
    }
  });

  test('groupByDate preserves first-seen group order', () {
    final groups = groupByDate(all);
    expect(groups.keys.first, startsWith('Today'));
    expect(groups.keys.length, greaterThanOrEqualTo(2));
  });
}
