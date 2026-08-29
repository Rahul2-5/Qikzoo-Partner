import 'package:delivery_partner_app/shared/widgets/navigation/floating_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('moves the active indicator when a destination is selected',
      (tester) async {
    tester.view.physicalSize = const Size(390, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var selectedIndex = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingBottomNav(
              currentIndex: selectedIndex,
              onTap: (index) => setState(() => selectedIndex = index),
              items: const [
                NavItem(
                    icon: Icons.home,
                    activeIcon: Icons.home,
                    asset: 'assets/icons/home.webp',
                    label: 'Home'),
                NavItem(
                    icon: Icons.work,
                    activeIcon: Icons.work,
                    asset: 'assets/icons/scooter_rider.webp',
                    label: 'Gigs'),
                NavItem(
                    icon: Icons.receipt,
                    activeIcon: Icons.receipt,
                    asset: 'assets/icons/order_bag_cloche.webp',
                    label: 'Orders'),
                NavItem(
                    icon: Icons.bar_chart,
                    activeIcon: Icons.bar_chart,
                    asset: 'assets/icons/cash_payment.webp',
                    label: 'Earnings'),
                NavItem(
                    icon: Icons.person,
                    activeIcon: Icons.person,
                    asset: 'assets/icons/user.webp',
                    label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );

    // The current design has no separate sliding indicator bar — the
    // selected cell's own glyph is scaled up in place (via the
    // AnimatedScale nested inside _NavCell's AnimatedContainer — distinct
    // from AppPressEffect's own unrelated tap-scale AnimatedScale one
    // level up), and tapping a different label calls onTap with its index
    // for the caller to update currentIndex.
    Iterable<double> glyphScales() => tester
        .widgetList<AnimatedScale>(find.descendant(
          of: find.byType(AnimatedContainer),
          matching: find.byType(AnimatedScale),
        ))
        .map((w) => w.scale);

    final scales = glyphScales().toList();
    expect(scales[0], 1.06); // Home (index 0) starts selected
    expect(scales.skip(1), everyElement(1.0));

    await tester.tap(find.text('Earnings'));
    await tester.pumpAndSettle();

    expect(selectedIndex, 3);
    final updatedScales = glyphScales().toList();
    expect(updatedScales[3], 1.06);
    expect(updatedScales[0], 1.0);
  });

  testWidgets(
      'renders every label on a single line with ellipsis overflow protection, even on narrow phones',
      (tester) async {
    tester.view.physicalSize = const Size(360, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingBottomNav(
            currentIndex: 3,
            onTap: (_) {},
            items: const [
              NavItem(
                  icon: Icons.home,
                  activeIcon: Icons.home,
                  asset: 'assets/icons/home.webp',
                  label: 'Home'),
              NavItem(
                  icon: Icons.work,
                  activeIcon: Icons.work,
                  asset: 'assets/icons/scooter_rider.webp',
                  label: 'Gigs'),
              NavItem(
                  icon: Icons.receipt,
                  activeIcon: Icons.receipt,
                  asset: 'assets/icons/order_bag_cloche.webp',
                  label: 'Orders'),
              NavItem(
                  icon: Icons.bar_chart,
                  activeIcon: Icons.bar_chart,
                  asset: 'assets/icons/cash_payment.webp',
                  label: 'Earnings'),
              NavItem(
                  icon: Icons.person,
                  activeIcon: Icons.person,
                  asset: 'assets/icons/user.webp',
                  label: 'Profile'),
            ],
          ),
        ),
      ),
    );

    for (final label in ['Home', 'Gigs', 'Orders', 'Earnings', 'Profile']) {
      final textWidget = tester.widget<Text>(find.text(label));
      expect(textWidget.maxLines, 1);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    }
    // No render-overflow ("yellow/black stripes") exception at this width.
    expect(tester.takeException(), isNull);
  });
}
