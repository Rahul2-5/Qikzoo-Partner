import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/earnings/widgets/total_earnings_card.dart';
import 'package:delivery_partner_app/features/earnings/widgets/earnings_breakdown_grid.dart';
import 'package:delivery_partner_app/models/earnings/earnings_models.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('TotalEarningsCard shows total and comparison', (tester) async {
    await tester.pumpWidget(wrap(const TotalEarningsCard(
      total: 2345.50,
      deltaPercent: 18,
      comparisonLabel: 'last week',
    )));
    expect(find.text('₹2,345.50'), findsOneWidget);
    expect(find.text('Total Earnings'), findsOneWidget);
    expect(find.textContaining('last week'), findsOneWidget);
  });

  testWidgets('EarningsBreakdownGrid renders all category labels and amounts',
      (tester) async {
    final cats = EarningsSummary.forPeriod(EarningsPeriod.thisWeek).categories;
    await tester.pumpWidget(wrap(EarningsBreakdownGrid(categories: cats)));
    expect(find.text('Delivery Earnings'), findsOneWidget);
    expect(find.text('Incentives'), findsOneWidget);
    expect(find.text('₹1,890.00'), findsOneWidget);
    expect(find.text('₹320.00'), findsOneWidget);
  });
}
