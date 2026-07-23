import 'package:equatable/equatable.dart';
import 'rider_order_model.dart';

/// The three filters `GET /rider/orders/history?status=` accepts exactly —
/// mirrors the backend's `RiderOrderHistoryQueryDto` allow-list.
enum OrderHistoryFilter {
  active,
  completed,
  cancelled;

  String get backendValue => switch (this) {
        OrderHistoryFilter.active => 'ACTIVE',
        OrderHistoryFilter.completed => 'COMPLETED',
        OrderHistoryFilter.cancelled => 'CANCELLED',
      };

  String get label => switch (this) {
        OrderHistoryFilter.active => 'Active',
        OrderHistoryFilter.completed => 'Completed',
        OrderHistoryFilter.cancelled => 'Cancelled',
      };
}

/// One page of `GET /rider/orders/history` — `{items, total, page, pageSize}`.
class OrderHistoryPageModel extends Equatable {
  final List<RiderOrderModel> items;
  final int total;
  final int page;
  final int pageSize;

  const OrderHistoryPageModel({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < total;

  factory OrderHistoryPageModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return OrderHistoryPageModel(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(RiderOrderModel.fromJson)
              .toList()
          : const [],
      total: json['total'] is num ? (json['total'] as num).toInt() : 0,
      page: json['page'] is num ? (json['page'] as num).toInt() : 1,
      pageSize: json['pageSize'] is num ? (json['pageSize'] as num).toInt() : 20,
    );
  }

  @override
  List<Object?> get props => [items, total, page, pageSize];
}
