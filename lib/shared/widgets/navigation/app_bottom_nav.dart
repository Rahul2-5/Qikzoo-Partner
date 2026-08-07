import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import 'floating_bottom_nav.dart';

/// The core destinations used by both compact and expanded navigation.
/// Keeping the data here prevents tablet navigation drifting from the phone's
/// bottom navigation.
const appTabRoutes = [
  AppRoutes.dashboard,
  AppRoutes.gigs,
  AppRoutes.orders,
  AppRoutes.earnings,
  AppRoutes.profile,
];

const appTabItems = [
  NavItem(
    icon: LucideIcons.home,
    activeIcon: LucideIcons.home,
    label: 'Home',
  ),
  NavItem(
    icon: LucideIcons.calendarClock,
    activeIcon: LucideIcons.calendarClock,
    label: 'Gigs',
  ),
  NavItem(
    icon: LucideIcons.receipt,
    activeIcon: LucideIcons.receipt,
    label: 'Orders',
  ),
  NavItem(
    icon: LucideIcons.barChart3,
    activeIcon: LucideIcons.barChart3,
    label: 'Earnings',
  ),
  NavItem(
    icon: LucideIcons.user,
    activeIcon: LucideIcons.user,
    label: 'Profile',
  ),
];

void navigateToTab(int index) {
  final route = appTabRoutes[index];
  if (Get.currentRoute != route) Get.offAllNamed(route);
}

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) => FloatingBottomNav(
        currentIndex: currentIndex,
        onTap: navigateToTab,
        items: appTabItems,
      );
}
