import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/earnings/widgets/earnings_trend_chart.dart';
import 'package:delivery_partner_app/models/earnings/earnings_models.dart';

void main() {
  testWidgets('renders one label per bar and the section title',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bars = EarningsSummary.forPeriod(EarningsPeriod.thisWeek).bars;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EarningsTrendChart(
          bars: bars,
          maxValue: 600,
          period: EarningsPeriod.thisWeek,
          onPeriodChanged: (_) {},
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Earnings Trend'), findsOneWidget);
    for (final b in bars) {
      expect(find.text(b.label), findsOneWidget);
    }
  });
}
