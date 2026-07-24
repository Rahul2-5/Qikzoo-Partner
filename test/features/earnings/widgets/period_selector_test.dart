import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/earnings/widgets/period_selector.dart';
import 'package:delivery_partner_app/models/earnings/earnings_models.dart';

void main() {
  testWidgets('shows the current period label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PeriodSelector(value: EarningsPeriod.thisWeek, onChanged: (_) {}),
      ),
    ));
    expect(find.text('This Week'), findsOneWidget);
  });

  testWidgets('selecting a period from the menu fires onChanged',
      (tester) async {
    EarningsPeriod? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PeriodSelector(
            value: EarningsPeriod.thisWeek, onChanged: (p) => picked = p),
      ),
    ));
    await tester.tap(find.text('This Week'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This Month').last);
    await tester.pumpAndSettle();
    expect(picked, EarningsPeriod.thisMonth);
  });
}
