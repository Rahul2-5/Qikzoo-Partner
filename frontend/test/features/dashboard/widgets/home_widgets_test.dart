import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/greeting_header.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/todays_earnings_card.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/stat_tile_row.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/offline_hero_card.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/waiting_for_orders_card.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('GreetingHeader toggle fires callback', (tester) async {
    var toggled = 0;
    await tester.pumpWidget(
        wrap(GreetingHeader(online: false, onToggleStatus: () => toggled++)));
    expect(find.text('Offline'), findsOneWidget);
    await tester.tap(find.text('Offline'));
    expect(toggled, 1);
  });

  testWidgets('TodaysEarningsCard shows precise amount', (tester) async {
    await tester.pumpWidget(wrap(const TodaysEarningsCard(amount: 920.5)));
    expect(find.text('₹920.50'), findsOneWidget);
    expect(find.text("Today's Earnings"), findsOneWidget);
  });

  testWidgets('StatTileRow renders three stats', (tester) async {
    await tester.pumpWidget(wrap(const StatTileRow(
        deliveries: 12, hoursOnline: '4h 30m', rating: 4.8)));
    expect(find.text('12'), findsOneWidget);
    expect(find.text('4h 30m'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
  });

  testWidgets('OfflineHeroCard Go Online fires callback', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(wrap(OfflineHeroCard(onGoOnline: () => pressed++)));
    await tester.tap(find.text('Go Online'));
    expect(pressed, 1);
  });

  testWidgets('WaitingForOrdersCard shows searching copy', (tester) async {
    await tester.pumpWidget(wrap(const WaitingForOrdersCard()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Finding orders near you…'), findsOneWidget);
  });
}
