import 'package:delivery_partner_app/shared/widgets/navigation/floating_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
