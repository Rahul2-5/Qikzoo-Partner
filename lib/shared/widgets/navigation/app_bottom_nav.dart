import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import 'floating_bottom_nav.dart';

// Wallet/Earnings are a later phase (not linked from nav yet) — only the
// three screens with a real, production implementation are visible tabs.
const _tabRoutes = [
  AppRoutes.dashboard,
  AppRoutes.orders,
  AppRoutes.profile,
];

void navigateToTab(int index) {
  final route = _tabRoutes[index];
  if (Get.currentRoute != route) Get.offAllNamed(route);
}

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) => FloatingBottomNav(
        currentIndex: currentIndex,
        onTap: navigateToTab,
        items: const [
          NavItem(
              icon: LucideIcons.home,
              activeIcon: LucideIcons.home,
              label: 'Home'),
          NavItem(
              icon: LucideIcons.receipt,
              activeIcon: LucideIcons.receipt,
              label: 'Orders'),
          NavItem(
              icon: LucideIcons.user,
              activeIcon: LucideIcons.user,
              label: 'Profile'),
        ],
      );
}
