import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/order_progress_tracker.dart';
import 'package:delivery_partner_app/models/orders/order_model.dart';

Widget host(OrderStatus status) => MaterialApp(
      home: Scaffold(
        body: OrderProgressTracker(status: status),
      ),
    );

void main() {
  testWidgets('renders all three stage labels', (tester) async {
    await tester.pumpWidget(host(OrderStatus.accepted));
    expect(find.text('Restaurant'), findsOneWidget);
    expect(find.text('On the way'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
  });

  testWidgets('completed stage index grows with status', (tester) async {
    expect(OrderProgressTracker.stageForStatus(OrderStatus.accepted), 0);
    expect(
        OrderProgressTracker.stageForStatus(OrderStatus.navigatingToCustomer), 1);
    expect(OrderProgressTracker.stageForStatus(OrderStatus.deliveryConfirmed), 2);
  });
}
