import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/earnings/earnings_models.dart';

void main() {
  test('chartCeiling rounds up to the next multiple of 200 (min 200)', () {
    expect(chartCeiling(0), 200);
    expect(chartCeiling(200), 200);
    expect(chartCeiling(201), 400);
    expect(chartCeiling(560), 600);
    expect(chartCeiling(2345.50), 2400);
  });

  test('DeltaDirection derives from percent sign', () {
    expect(const EarningsCategory(label: 'a', amount: 1, deltaPercent: 5).direction,
        DeltaDirection.up);
    expect(const EarningsCategory(label: 'a', amount: 1, deltaPercent: -3).direction,
        DeltaDirection.down);
    expect(const EarningsCategory(label: 'a', amount: 1, deltaPercent: 0).direction,
        DeltaDirection.flat);
  });

  test('forPeriod returns documented totals and 4 categories', () {
    final week = EarningsSummary.forPeriod(EarningsPeriod.thisWeek);
    expect(week.total, 2345.50);
    expect(week.deltaPercent, 18);
    expect(week.categories.length, 4);
    expect(week.bars.length, 7);

    final month = EarningsSummary.forPeriod(EarningsPeriod.thisMonth);
    expect(month.total, 7630.75);
    expect(month.bars.length, 4);
  });

  test('category amounts sum to the total for each period', () {
    for (final p in EarningsPeriod.values) {
      final s = EarningsSummary.forPeriod(p);
      final sum = s.categories.fold<double>(0, (a, c) => a + c.amount);
      expect(sum, closeTo(s.total, 0.001), reason: 'period $p');
    }
  });

  test('maxBarValue is a multiple of 200 and >= every bar', () {
    final s = EarningsSummary.forPeriod(EarningsPeriod.thisWeek);
    for (final b in s.bars) {
      expect(s.maxBarValue, greaterThanOrEqualTo(b.value));
    }
    expect(s.maxBarValue % 200, 0);
  });
}
