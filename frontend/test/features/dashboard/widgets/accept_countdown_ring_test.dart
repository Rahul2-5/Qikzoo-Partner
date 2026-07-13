import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/core/theme/app_colors.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/accept_countdown_ring.dart';

void main() {
  test('colorForRemaining crosses thresholds at 10s and 5s', () {
    expect(AcceptCountdownRing.colorForRemaining(30), AppColors.success);
    expect(AcceptCountdownRing.colorForRemaining(10), AppColors.success);
    expect(AcceptCountdownRing.colorForRemaining(9), AppColors.warning);
    expect(AcceptCountdownRing.colorForRemaining(5), AppColors.warning);
    expect(AcceptCountdownRing.colorForRemaining(4), AppColors.error);
  });

  testWidgets('calls onExpired once after the duration elapses', (tester) async {
    var expired = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AcceptCountdownRing(seconds: 2, onExpired: () => expired++),
      ),
    ));
    expect(expired, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 50));
    expect(expired, 1);
  });
}
