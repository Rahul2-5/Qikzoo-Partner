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
                    icon: Icons.home, activeIcon: Icons.home, label: 'Home'),
                NavItem(
                    icon: Icons.work, activeIcon: Icons.work, label: 'Gigs'),
                NavItem(
                    icon: Icons.receipt,
                    activeIcon: Icons.receipt,
                    label: 'Orders'),
                NavItem(
                    icon: Icons.bar_chart,
                    activeIcon: Icons.bar_chart,
                    label: 'Earnings'),
                NavItem(
                    icon: Icons.person,
                    activeIcon: Icons.person,
                    label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );

    final indicator = find.byKey(const Key('active-navigation-indicator'));
    final initialLeft = tester.widget<AnimatedPositioned>(indicator).left!;

    await tester.tap(find.text('Earnings'));
    await tester.pump();

    expect(tester.widget<AnimatedPositioned>(indicator).left,
        greaterThan(initialLeft));
  });

  testWidgets('bottom-navigation labels are not ellipsized on narrow phones',
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
              NavItem(icon: Icons.home, activeIcon: Icons.home, label: 'Home'),
              NavItem(icon: Icons.work, activeIcon: Icons.work, label: 'Gigs'),
              NavItem(
                  icon: Icons.receipt,
                  activeIcon: Icons.receipt,
                  label: 'Orders'),
              NavItem(
                  icon: Icons.bar_chart,
                  activeIcon: Icons.bar_chart,
                  label: 'Earnings'),
              NavItem(
                  icon: Icons.person,
                  activeIcon: Icons.person,
                  label: 'Profile'),
            ],
          ),
        ),
      ),
    );

    for (final label in ['Home', 'Gigs', 'Orders', 'Earnings', 'Profile']) {
      expect(tester.widget<Text>(find.text(label)).overflow, isNull);
    }
  });
}
