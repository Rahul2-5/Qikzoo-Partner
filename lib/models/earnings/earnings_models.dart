import 'package:equatable/equatable.dart';

enum EarningsPeriod {
  today,
  thisWeek,
  lifetime;

  String get label => switch (this) {
        EarningsPeriod.today => 'Today',
        EarningsPeriod.thisWeek => 'This Week',
        EarningsPeriod.lifetime => 'Lifetime',
      };
}

/// One bucket of `GET /rider/earnings/summary` (`today`/`thisWeek`/`lifetime`)
/// — `RiderEarningsService.aggregate()` on the backend. No category
/// breakdown (delivery pay vs incentives vs distance pay) exists server-side
/// — only a single earnings sum plus tips, so that's all this exposes.
class EarningsBucket extends Equatable {
  final int deliveries;
  final int earningsPaise;
  final int tipsPaise;

  const EarningsBucket({
    required this.deliveries,
    required this.earningsPaise,
    required this.tipsPaise,
  });

  static const zero = EarningsBucket(deliveries: 0, earningsPaise: 0, tipsPaise: 0);

  double get earnings => earningsPaise / 100;
  double get tips => tipsPaise / 100;
  double get total => (earningsPaise + tipsPaise) / 100;

  factory EarningsBucket.fromJson(Map<String, dynamic> json) => EarningsBucket(
        deliveries: json['deliveries'] is num ? (json['deliveries'] as num).toInt() : 0,
        earningsPaise:
            json['earningsPaise'] is num ? (json['earningsPaise'] as num).toInt() : 0,
        tipsPaise: json['tipsPaise'] is num ? (json['tipsPaise'] as num).toInt() : 0,
      );

  @override
  List<Object?> get props => [deliveries, earningsPaise, tipsPaise];
}

class EarningsSummaryModel extends Equatable {
  final EarningsBucket today;
  final EarningsBucket thisWeek;
  final EarningsBucket lifetime;

  const EarningsSummaryModel({
    required this.today,
    required this.thisWeek,
    required this.lifetime,
  });

  static const empty = EarningsSummaryModel(
    today: EarningsBucket.zero,
    thisWeek: EarningsBucket.zero,
    lifetime: EarningsBucket.zero,
  );

  EarningsBucket forPeriod(EarningsPeriod period) => switch (period) {
        EarningsPeriod.today => today,
        EarningsPeriod.thisWeek => thisWeek,
        EarningsPeriod.lifetime => lifetime,
      };

  factory EarningsSummaryModel.fromJson(Map<String, dynamic> json) => EarningsSummaryModel(
        today: EarningsBucket.fromJson(_asMap(json['today'])),
        thisWeek: EarningsBucket.fromJson(_asMap(json['thisWeek'])),
        lifetime: EarningsBucket.fromJson(_asMap(json['lifetime'])),
      );

  static Map<String, dynamic> _asMap(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  @override
  List<Object?> get props => [today, thisWeek, lifetime];
}

/// One row of `GET /rider/earnings/history` — a delivered `RiderOrder`,
/// most recent first. This is a per-delivery earnings record, not a
/// bank-payout/settlement event (the backend has no settlement-batch
/// endpoint exposed to the rider app yet).
class EarningsHistoryEntry extends Equatable {
  final String id;
  final String? orderNumber;
  final int earningsPaise;
  final int tipsPaise;
  final DateTime? deliveredAt;

  const EarningsHistoryEntry({
    required this.id,
    required this.orderNumber,
    required this.earningsPaise,
    required this.tipsPaise,
    required this.deliveredAt,
  });

  double get total => (earningsPaise + tipsPaise) / 100;

  factory EarningsHistoryEntry.fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    return EarningsHistoryEntry(
      id: json['id'] is String ? json['id'] as String : '',
      orderNumber: order is Map && order['orderNumber'] is String
          ? order['orderNumber'] as String
          : null,
      earningsPaise:
          json['earningsPaise'] is num ? (json['earningsPaise'] as num).toInt() : 0,
      tipsPaise: json['tipsPaise'] is num ? (json['tipsPaise'] as num).toInt() : 0,
      deliveredAt: json['deliveredAt'] is String
          ? DateTime.tryParse(json['deliveredAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, orderNumber, earningsPaise, tipsPaise, deliveredAt];
}

class EarningsHistoryPage extends Equatable {
  final List<EarningsHistoryEntry> items;
  final int total;
  final int page;
  final int pageSize;

  const EarningsHistoryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  static const empty = EarningsHistoryPage(items: [], total: 0, page: 1, pageSize: 20);

  bool get hasMore => items.length + (page - 1) * pageSize < total;

  factory EarningsHistoryPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    return EarningsHistoryPage(
      items: items is List
          ? items
              .whereType<Map<String, dynamic>>()
              .map(EarningsHistoryEntry.fromJson)
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
