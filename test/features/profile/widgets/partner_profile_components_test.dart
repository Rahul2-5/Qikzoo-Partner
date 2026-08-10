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

  testWidgets('profile actions and menu tiles keep a compact mobile height',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              PartnerQuickAction(
                icon: LucideIcons.circleDollarSign,
                iconColor: Colors.green,
                title: 'Gigs history',
                subtitle: 'View past gigs',
                onTap: () {},
              ),
              PartnerProfileMenuTile(
                icon: LucideIcons.headphones,
                title: 'Help centre',
                subtitle: 'Get help and support',
                color: Colors.blue,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final quickAction = find.byKey(const ValueKey('partner-quick-action-card'));
    final menuTile = find.byKey(const ValueKey('partner-profile-menu-tile'));
    final quickActionHeight = tester.getSize(quickAction).height;
    final menuTileHeight = tester.getSize(menuTile).height;

    expect(quickActionHeight, greaterThanOrEqualTo(128));
    expect(menuTileHeight, greaterThanOrEqualTo(64));
  });
}
