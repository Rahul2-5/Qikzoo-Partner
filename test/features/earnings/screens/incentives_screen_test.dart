// IncentivesScreen (reached via AppRoutes.incentives, e.g. MoreScreen's
// "Refer & earn" menu row) is a static referral-code sharing screen — a
// banner, the rider's referral code with a copy action, a share button, and
// "How it works" steps. It has no incentive-tracking list or empty state at
// all, so the old "No active incentives" assertion tested UI that doesn't
// exist here; fixed to check the screen's real content instead.

import 'package:delivery_partner_app/core/theme/app_theme.dart';
import 'package:delivery_partner_app/features/earnings/screens/incentives_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cards reflow on a narrow phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: const IncentivesScreen(),
      ),
    );

    expect(find.text('QIKPARTNER7700'), findsOneWidget);
    expect(find.text('Share Link with Friends'), findsOneWidget);
    expect(find.text('How it works'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
