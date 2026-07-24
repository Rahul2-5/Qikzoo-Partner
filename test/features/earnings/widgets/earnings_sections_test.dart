import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/earnings/widgets/earnings_header.dart';
import 'package:delivery_partner_app/features/earnings/widgets/earnings_history_list.dart';
import 'package:delivery_partner_app/features/earnings/widgets/next_payout_card.dart';
import 'package:delivery_partner_app/models/earnings/earnings_models.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('EarningsHeader shows title and current period', (tester) async {
    await tester.pumpWidget(wrap(EarningsHeader(
        period: EarningsPeriod.thisWeek, onPeriodChanged: (_) {})));
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
  });

  testWidgets('EarningsHistoryList renders each entry with a Paid chip',
      (tester) async {
    final history = EarningsSummary.forPeriod(EarningsPeriod.thisWeek).history;
    await tester.pumpWidget(wrap(EarningsHistoryList(history: history)));
    expect(find.text(history.first.dateRange), findsOneWidget);
    expect(find.text('Paid'), findsNWidgets(history.length));
  });

  testWidgets('NextPayoutCard shows bank, amount and date', (tester) async {
    const payout = PayoutInfo(
        bankName: 'HDFC Bank',
        maskedAccount: '4321',
        amount: 2345.50,
        date: '15 May 2025');
    await tester.pumpWidget(wrap(const NextPayoutCard(payout: payout)));
    expect(find.text('Next Payout'), findsOneWidget);
    expect(find.textContaining('4321'), findsOneWidget);
    expect(find.text('₹2,345.50'), findsOneWidget);
    expect(find.text('15 May 2025'), findsOneWidget);
  });
}
