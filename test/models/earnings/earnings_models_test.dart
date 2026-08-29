import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/earnings/earnings_models.dart';

void main() {
  group('EarningsBucket', () {
    test('total is earnings + tips, in rupees', () {
      const bucket = EarningsBucket(deliveries: 3, earningsPaise: 12000, tipsPaise: 500);
      expect(bucket.earnings, 120.0);
      expect(bucket.tips, 5.0);
      expect(bucket.total, 125.0);
    });

    test('fromJson parses the real /rider/earnings/summary bucket shape', () {
      final bucket = EarningsBucket.fromJson(const {
        'deliveries': 4,
        'earningsPaise': 20000,
        'tipsPaise': 1000,
      });
      expect(bucket.deliveries, 4);
      expect(bucket.earningsPaise, 20000);
      expect(bucket.tipsPaise, 1000);
    });

    test('fromJson defaults missing/malformed fields to zero', () {
      final bucket = EarningsBucket.fromJson(const {});
      expect(bucket, EarningsBucket.zero);
    });
  });

  group('EarningsSummaryModel', () {
    test('fromJson parses today/thisWeek/lifetime buckets', () {
      final summary = EarningsSummaryModel.fromJson(const {
        'today': {'deliveries': 1, 'earningsPaise': 5000, 'tipsPaise': 0},
        'thisWeek': {'deliveries': 5, 'earningsPaise': 25000, 'tipsPaise': 1000},
        'lifetime': {'deliveries': 100, 'earningsPaise': 500000, 'tipsPaise': 20000},
      });
      expect(summary.today.deliveries, 1);
      expect(summary.thisWeek.deliveries, 5);
      expect(summary.lifetime.deliveries, 100);
    });

    test('forPeriod selects the matching bucket', () {
      const summary = EarningsSummaryModel(
        today: EarningsBucket(deliveries: 1, earningsPaise: 100, tipsPaise: 0),
        thisWeek: EarningsBucket(deliveries: 2, earningsPaise: 200, tipsPaise: 0),
        lifetime: EarningsBucket(deliveries: 3, earningsPaise: 300, tipsPaise: 0),
      );
      expect(summary.forPeriod(EarningsPeriod.today).deliveries, 1);
      expect(summary.forPeriod(EarningsPeriod.thisWeek).deliveries, 2);
      expect(summary.forPeriod(EarningsPeriod.lifetime).deliveries, 3);
    });
  });

  group('EarningsHistoryEntry', () {
    test('fromJson parses a delivered RiderOrder row with its order number', () {
      final entry = EarningsHistoryEntry.fromJson(const {
        'id': 'ro-1',
        'earningsPaise': 4000,
        'tipsPaise': 500,
        'deliveredAt': '2026-08-01T10:00:00.000Z',
        'order': {'orderNumber': 'BR-42', 'branchId': 'branch-1'},
      });
      expect(entry.id, 'ro-1');
      expect(entry.orderNumber, 'BR-42');
      expect(entry.total, 45.0);
      expect(entry.deliveredAt, isNotNull);
    });

    test('fromJson tolerates a missing order number', () {
      final entry = EarningsHistoryEntry.fromJson(const {
        'id': 'ro-2',
        'earningsPaise': 1000,
        'tipsPaise': 0,
        'deliveredAt': null,
      });
      expect(entry.orderNumber, isNull);
      expect(entry.deliveredAt, isNull);
    });
  });

  group('EarningsHistoryPage', () {
    test('fromJson parses items/total/page/pageSize', () {
      final page = EarningsHistoryPage.fromJson(const {
        'items': [
          {'id': 'ro-1', 'earningsPaise': 1000, 'tipsPaise': 0, 'deliveredAt': null},
        ],
        'total': 5,
        'page': 1,
        'pageSize': 20,
      });
      expect(page.items.length, 1);
      expect(page.total, 5);
    });

    test('hasMore is true while more pages remain', () {
      const page = EarningsHistoryPage(
        items: [
          EarningsHistoryEntry(
              id: '1', orderNumber: null, earningsPaise: 0, tipsPaise: 0, deliveredAt: null),
        ],
        total: 5,
        page: 1,
        pageSize: 1,
      );
      expect(page.hasMore, isTrue);
    });

    test('hasMore is false on the last page', () {
      const page = EarningsHistoryPage(
        items: [
          EarningsHistoryEntry(
              id: '1', orderNumber: null, earningsPaise: 0, tipsPaise: 0, deliveredAt: null),
        ],
        total: 1,
        page: 1,
        pageSize: 20,
      );
      expect(page.hasMore, isFalse);
    });
  });
}
