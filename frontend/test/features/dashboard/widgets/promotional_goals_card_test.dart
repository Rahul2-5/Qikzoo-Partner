import 'package:delivery_partner_app/core/utils/currency_formatter.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/promotional_goals_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

void main() {
  testWidgets('shows the promotion and both delivery reward milestones',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        const PromotionalGoalsCard(
          completedOrders: 36,
          offerEndsLabel: 'Ends Sunday, 11:59 PM',
          goals: [
            DeliveryGoal(deliveries: 48, reward: 150),
            DeliveryGoal(deliveries: 60, reward: 250),
          ],
        ),
      ),
    );

    expect(find.text('Weekly delivery quest'), findsOneWidget);
    expect(find.text('PROMO'), findsOneWidget);
    expect(find.text('48 deliveries'), findsOneWidget);
    expect(find.text('60 deliveries'), findsOneWidget);
    expect(
      find.text('12 more to unlock ${CurrencyFormatter.rupees(150)}'),
      findsOneWidget,
    );
    expect(find.text(CurrencyFormatter.rupees(150)), findsOneWidget);
    expect(find.text(CurrencyFormatter.rupees(250)), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows completion state after the top milestone', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PromotionalGoalsCard(
          completedOrders: 60,
          offerEndsLabel: 'Ends tonight',
          goals: [
            DeliveryGoal(deliveries: 48, reward: 150),
            DeliveryGoal(deliveries: 60, reward: 250),
          ],
        ),
      ),
    );

    expect(find.text('All goals completed'), findsOneWidget);
    expect(find.text('Milestone completed'), findsNWidgets(2));
  });
}
