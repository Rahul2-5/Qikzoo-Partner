import 'package:delivery_partner_app/core/theme/app_theme.dart';
import 'package:delivery_partner_app/features/profile/widgets/partner_profile_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  testWidgets('quick-action labels are never ellipsized on a narrow screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 100,
            child: PartnerQuickAction(
              icon: LucideIcons.circleDollarSign,
              iconColor: Colors.green,
              title: 'Gigs history',
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Gigs history'));
    expect(label.overflow, isNull);
    expect(label.textAlign, TextAlign.center);
  });
}
