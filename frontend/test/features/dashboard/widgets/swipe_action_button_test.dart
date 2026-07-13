import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/swipe_action_button.dart';

Widget host(VoidCallback onConfirmed) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: SwipeActionButton(
                label: 'Confirm Pickup', onConfirmed: onConfirmed),
          ),
        ),
      ),
    );

void main() {
  testWidgets('full swipe fires onConfirmed once', (tester) async {
    var count = 0;
    await tester.pumpWidget(host(() => count++));
    await tester.drag(find.byType(SwipeActionButton), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(count, 1);
  });

  testWidgets('short swipe does not fire and springs back', (tester) async {
    var count = 0;
    await tester.pumpWidget(host(() => count++));
    await tester.drag(find.byType(SwipeActionButton), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(count, 0);
  });
}
