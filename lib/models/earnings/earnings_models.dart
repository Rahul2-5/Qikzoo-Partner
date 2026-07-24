import 'package:equatable/equatable.dart';

enum EarningsPeriod {
  thisWeek,
  lastWeek,
  thisMonth;

  String get label => switch (this) {
        EarningsPeriod.thisWeek => 'This Week',
        EarningsPeriod.lastWeek => 'Last Week',
        EarningsPeriod.thisMonth => 'This Month',
      };

  String get comparisonLabel =>
      this == EarningsPeriod.thisMonth ? 'last month' : 'last week';
}

enum DeltaDirection { up, down, flat }

DeltaDirection _directionFor(double percent) {
  if (percent > 0) return DeltaDirection.up;
  if (percent < 0) return DeltaDirection.down;
  return DeltaDirection.flat;
}

/// Rounds a chart's max value up to the next multiple of 200 (minimum 200).
double chartCeiling(double maxValue) {
  if (maxValue <= 200) return 200;
  return (maxValue / 200).ceil() * 200;
}

class EarningsCategory extends Equatable {
  final String label;
  final double amount;
  final double deltaPercent;

  const EarningsCategory({
    required this.label,
    required this.amount,
    required this.deltaPercent,
  });

  DeltaDirection get direction => _directionFor(deltaPercent);

  @override
  List<Object?> get props => [label, amount, deltaPercent];
}

class ChartBar extends Equatable {
  final String label;
  final double value;

  const ChartBar({required this.label, required this.value});

  @override
  List<Object?> get props => [label, value];
}

class EarningsHistoryEntry extends Equatable {
  final String dateRange;
  final String relativeLabel;
  final double amount;
  final bool paid;

  const EarningsHistoryEntry({
    required this.dateRange,
    required this.relativeLabel,
    required this.amount,
    required this.paid,
  });

  @override
  List<Object?> get props => [dateRange, relativeLabel, amount, paid];
}

class PayoutInfo extends Equatable {
  final String bankName;
  final String maskedAccount;
  final double amount;
  final String date;

  const PayoutInfo({
    required this.bankName,
    required this.maskedAccount,
    required this.amount,
    required this.date,
  });

  @override
  List<Object?> get props => [bankName, maskedAccount, amount, date];
}

class EarningsSummary extends Equatable {
  final EarningsPeriod period;
  final double total;
  final double deltaPercent;
  final List<EarningsCategory> categories;
  final List<ChartBar> bars;
  final List<EarningsHistoryEntry> history;
  final PayoutInfo payout;

  const EarningsSummary({
    required this.period,
    required this.total,
    required this.deltaPercent,
    required this.categories,
    required this.bars,
    required this.history,
    required this.payout,
  });

  double get maxBarValue {
    final peak = bars.fold<double>(0, (m, b) => b.value > m ? b.value : m);
    return chartCeiling(peak);
  }

  static const _history = [
    EarningsHistoryEntry(
        dateRange: '5 May – 11 May 2025',
        relativeLabel: 'This Week',
        amount: 2345.50,
        paid: true),
    EarningsHistoryEntry(
        dateRange: '28 Apr – 4 May 2025',
        relativeLabel: 'Last Week',
        amount: 1987.75,
        paid: true),
    EarningsHistoryEntry(
        dateRange: '21 Apr – 27 Apr 2025',
        relativeLabel: '2 Weeks Ago',
        amount: 1765.00,
        paid: true),
    EarningsHistoryEntry(
        dateRange: '14 Apr – 20 Apr 2025',
        relativeLabel: '3 Weeks Ago',
        amount: 1532.50,
        paid: true),
  ];

  factory EarningsSummary.forPeriod(EarningsPeriod period) {
    switch (period) {
      case EarningsPeriod.thisWeek:
        return const EarningsSummary(
          period: EarningsPeriod.thisWeek,
          total: 2345.50,
          deltaPercent: 18,
          categories: [
            EarningsCategory(
                label: 'Delivery Earnings', amount: 1890, deltaPercent: 16),
            EarningsCategory(label: 'Incentives', amount: 320, deltaPercent: 25),
            EarningsCategory(
                label: 'Distance Pay', amount: 105.50, deltaPercent: 10),
            EarningsCategory(
                label: 'Other Earnings', amount: 30, deltaPercent: 0),
          ],
          bars: [
            ChartBar(label: 'Mon', value: 280),
            ChartBar(label: 'Tue', value: 310),
            ChartBar(label: 'Wed', value: 420),
            ChartBar(label: 'Thu', value: 560),
            ChartBar(label: 'Fri', value: 340),
            ChartBar(label: 'Sat', value: 275),
            ChartBar(label: 'Sun', value: 160),
          ],
          history: _history,
          payout: PayoutInfo(
              bankName: 'HDFC Bank',
              maskedAccount: '4321',
              amount: 2345.50,
              date: '15 May 2025'),
        );
      case EarningsPeriod.lastWeek:
        return const EarningsSummary(
          period: EarningsPeriod.lastWeek,
          total: 1987.75,
          deltaPercent: 12,
          categories: [
            EarningsCategory(
                label: 'Delivery Earnings', amount: 1590, deltaPercent: 10),
            EarningsCategory(label: 'Incentives', amount: 270, deltaPercent: 18),
            EarningsCategory(
                label: 'Distance Pay', amount: 97.75, deltaPercent: 8),
            EarningsCategory(
                label: 'Other Earnings', amount: 30, deltaPercent: 0),
          ],
          bars: [
            ChartBar(label: 'Mon', value: 230),
            ChartBar(label: 'Tue', value: 260),
            ChartBar(label: 'Wed', value: 340),
            ChartBar(label: 'Thu', value: 450),
            ChartBar(label: 'Fri', value: 300),
            ChartBar(label: 'Sat', value: 220),
            ChartBar(label: 'Sun', value: 187.75),
          ],
          history: _history,
          payout: PayoutInfo(
              bankName: 'HDFC Bank',
              maskedAccount: '4321',
              amount: 1987.75,
              date: '15 May 2025'),
        );
      case EarningsPeriod.thisMonth:
        return const EarningsSummary(
          period: EarningsPeriod.thisMonth,
          total: 7630.75,
          deltaPercent: 22,
          categories: [
            EarningsCategory(
                label: 'Delivery Earnings', amount: 6100, deltaPercent: 20),
            EarningsCategory(
                label: 'Incentives', amount: 1050, deltaPercent: 28),
            EarningsCategory(
                label: 'Distance Pay', amount: 400.75, deltaPercent: 12),
            EarningsCategory(
                label: 'Other Earnings', amount: 80, deltaPercent: 0),
          ],
          bars: [
            ChartBar(label: 'W1', value: 1532.50),
            ChartBar(label: 'W2', value: 1765),
            ChartBar(label: 'W3', value: 1987.75),
            ChartBar(label: 'W4', value: 2345.50),
          ],
          history: _history,
          payout: PayoutInfo(
              bankName: 'HDFC Bank',
              maskedAccount: '4321',
              amount: 2345.50,
              date: '15 May 2025'),
        );
    }
  }

  @override
  List<Object?> get props =>
      [period, total, deltaPercent, categories, bars, history, payout];
}
