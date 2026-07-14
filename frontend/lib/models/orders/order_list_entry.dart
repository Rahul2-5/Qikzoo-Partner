import 'package:equatable/equatable.dart';

enum OrderListStatus { upcoming, completed, cancelled }

enum OrderBadge {
  newOrder,
  delivered,
  cancelled;

  String get label => switch (this) {
        OrderBadge.newOrder => 'New',
        OrderBadge.delivered => 'Delivered',
        OrderBadge.cancelled => 'Cancelled',
      };
}

enum OrdersTab {
  all,
  upcoming,
  completed,
  cancelled;

  String get label => switch (this) {
        OrdersTab.all => 'All Orders',
        OrdersTab.upcoming => 'Upcoming',
        OrdersTab.completed => 'Completed',
        OrdersTab.cancelled => 'Cancelled',
      };

  bool matches(OrderListEntry e) => switch (this) {
        OrdersTab.all => true,
        OrdersTab.upcoming => e.status == OrderListStatus.upcoming,
        OrdersTab.completed => e.status == OrderListStatus.completed,
        OrdersTab.cancelled => e.status == OrderListStatus.cancelled,
      };
}

enum OrdersSort {
  newest,
  highestEarning;

  String get label => switch (this) {
        OrdersSort.newest => 'Newest',
        OrdersSort.highestEarning => 'Highest earning',
      };
}

enum OrdersDateFilter {
  all,
  today;

  String get label => switch (this) {
        OrdersDateFilter.all => 'All time',
        OrdersDateFilter.today => 'Today',
      };
}

class OrderListEntry extends Equatable {
  final String id;
  final String restaurantName;
  final String restaurantArea;
  final String dropAddress;
  final double distanceKm;
  final String timeAwayLabel;
  final double amount;
  final String timeLabel;
  final String dateGroup;
  final OrderListStatus status;
  final OrderBadge badge;

  const OrderListEntry({
    required this.id,
    required this.restaurantName,
    required this.restaurantArea,
    required this.dropAddress,
    required this.distanceKm,
    required this.timeAwayLabel,
    required this.amount,
    required this.timeLabel,
    required this.dateGroup,
    required this.status,
    required this.badge,
  });

  static List<OrderListEntry> mockList() => const [
        OrderListEntry(
          id: '#171287364912',
          restaurantName: 'The Biryani House',
          restaurantArea: 'Goregaon West, Mumbai',
          dropAddress: 'Sundervan Complex, Andheri West, Mumbai',
          distanceKm: 4.2,
          timeAwayLabel: '12 mins away',
          amount: 38.50,
          timeLabel: '11:30 AM',
          dateGroup: 'Today, 12 May 2025',
          status: OrderListStatus.upcoming,
          badge: OrderBadge.newOrder,
        ),
        OrderListEntry(
          id: '#171287124578',
          restaurantName: 'The Biryani House',
          restaurantArea: 'Goregaon West, Mumbai',
          dropAddress: 'Lokhandwala Complex, Andheri West, Mumbai',
          distanceKm: 4.6,
          timeAwayLabel: '15 mins',
          amount: 46.00,
          timeLabel: '10:25 AM',
          dateGroup: 'Today, 12 May 2025',
          status: OrderListStatus.completed,
          badge: OrderBadge.delivered,
        ),
        OrderListEntry(
          id: '#171286889341',
          restaurantName: 'Burger Point',
          restaurantArea: 'Versova, Andheri West',
          dropAddress: 'Yari Road, Versova, Andheri West, Mumbai',
          distanceKm: 2.1,
          timeAwayLabel: '8 mins',
          amount: 32.50,
          timeLabel: '09:15 AM',
          dateGroup: 'Today, 12 May 2025',
          status: OrderListStatus.completed,
          badge: OrderBadge.delivered,
        ),
        OrderListEntry(
          id: '#171276554801',
          restaurantName: 'Pizza Corner',
          restaurantArea: 'Juhu Tara Road, Mumbai',
          dropAddress: 'JVPD Scheme, Juhu, Mumbai',
          distanceKm: 5.2,
          timeAwayLabel: '18 mins',
          amount: 55.00,
          timeLabel: '08:20 PM',
          dateGroup: 'Yesterday, 11 May 2025',
          status: OrderListStatus.completed,
          badge: OrderBadge.delivered,
        ),
        OrderListEntry(
          id: '#171276112233',
          restaurantName: 'Cake Studio',
          restaurantArea: 'Bandra West, Mumbai',
          dropAddress: 'Hill Road, Bandra West, Mumbai',
          distanceKm: 3.0,
          timeAwayLabel: '11 mins',
          amount: 0.00,
          timeLabel: '06:40 PM',
          dateGroup: 'Yesterday, 11 May 2025',
          status: OrderListStatus.cancelled,
          badge: OrderBadge.cancelled,
        ),
      ];

  @override
  List<Object?> get props => [
        id,
        restaurantName,
        restaurantArea,
        dropAddress,
        distanceKm,
        timeAwayLabel,
        amount,
        timeLabel,
        dateGroup,
        status,
        badge,
      ];
}

List<OrderListEntry> filterEntries({
  required List<OrderListEntry> all,
  required OrdersTab tab,
  required String query,
  required OrdersDateFilter dateFilter,
}) {
  final q = query.trim().toLowerCase();
  return all.where((e) {
    if (!tab.matches(e)) return false;
    if (dateFilter == OrdersDateFilter.today &&
        !e.dateGroup.startsWith('Today')) {
      return false;
    }
    if (q.isEmpty) return true;
    return e.restaurantName.toLowerCase().contains(q) ||
        e.id.toLowerCase().contains(q);
  }).toList();
}

List<OrderListEntry> sortEntries(
    List<OrderListEntry> entries, OrdersSort sort) {
  if (sort == OrdersSort.newest) return entries;
  final copy = [...entries];
  copy.sort((a, b) => b.amount.compareTo(a.amount));
  return copy;
}

Map<String, List<OrderListEntry>> groupByDate(List<OrderListEntry> entries) {
  final map = <String, List<OrderListEntry>>{};
  for (final e in entries) {
    map.putIfAbsent(e.dateGroup, () => []).add(e);
  }
  return map;
}
