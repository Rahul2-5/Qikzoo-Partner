import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import 'floating_bottom_nav.dart';

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
    asset: 'assets/icons/home.webp',
    label: 'Home',
  ),
  NavItem(
    icon: LucideIcons.calendarClock,
    activeIcon: LucideIcons.calendarClock,
    asset: 'assets/icons/scooter_rider.webp',
    label: 'Gigs',
  ),
  NavItem(
    icon: LucideIcons.receipt,
    activeIcon: LucideIcons.receipt,
    asset: 'assets/icons/order_bag_cloche.webp',
    label: 'Orders',
  ),
  NavItem(
    icon: LucideIcons.barChart3,
    activeIcon: LucideIcons.barChart3,
    asset: 'assets/icons/cash_payment.webp',
    label: 'Earnings',
  ),
  NavItem(
    icon: LucideIcons.user,
    activeIcon: LucideIcons.user,
    asset: 'assets/icons/user.webp',
    label: 'Profile',
  ),
];

void navigateToTab(int index) {
  if (index < 0 || index >= appTabRoutes.length) return;
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
