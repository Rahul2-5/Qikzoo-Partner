import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/orders/order_history_page_model.dart';

Map<String, dynamic> _riderOrderJson(String id) => {
      'id': id,
      'orderId': 'order-$id',
      'status': 'DELIVERED',
      'distanceKm': 2.0,
      'earningsPaise': 4000,
      'tipsPaise': 0,
      'assignedAt': '2026-07-23T10:00:00.000Z',
      'restaurant': {
        'name': 'Test Kitchen',
        'phone': '9000000001',
        'address': '1 MG Road',
        'landmark': null,
        'latitude': 12.9,
        'longitude': 77.6,
      },
      'order': {
        'id': 'order-$id',
        'orderNumber': id,
        'customerName': 'Test Customer',
        'customerPhone': '9999999999',
        'status': 'DELIVERED',
      },
    };

void main() {
  group('OrderHistoryFilter', () {
    test('backendValue matches the RiderOrderHistoryQueryDto allow-list exactly', () {
      expect(OrderHistoryFilter.active.backendValue, 'ACTIVE');
      expect(OrderHistoryFilter.completed.backendValue, 'COMPLETED');
      expect(OrderHistoryFilter.cancelled.backendValue, 'CANCELLED');
    });
  });

  group('OrderHistoryPageModel.fromJson', () {
    test('parses items, total, page, and pageSize', () {
      final page = OrderHistoryPageModel.fromJson({
        'items': [_riderOrderJson('1'), _riderOrderJson('2')],
        'total': 37,
        'page': 2,
        'pageSize': 20,
      });

      expect(page.items, hasLength(2));
      expect(page.total, 37);
      expect(page.page, 2);
      expect(page.pageSize, 20);
    });

    test('hasMore is true while more pages remain, false on the last page', () {
      final midway = OrderHistoryPageModel.fromJson({
        'items': [_riderOrderJson('1')],
        'total': 37,
        'page': 1,
        'pageSize': 20,
      });
      expect(midway.hasMore, isTrue);

      final last = OrderHistoryPageModel.fromJson({
        'items': [_riderOrderJson('1')],
        'total': 20,
        'page': 1,
        'pageSize': 20,
      });
      expect(last.hasMore, isFalse);
    });

    test('handles an empty page', () {
      final page = OrderHistoryPageModel.fromJson(const {
        'items': [],
        'total': 0,
        'page': 1,
        'pageSize': 20,
      });
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });
}
