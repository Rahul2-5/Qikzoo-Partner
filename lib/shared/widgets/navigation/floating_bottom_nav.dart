import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../motion/app_motion_widgets.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

class FloatingBottomNav extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final void Function(int) onTap;

  const FloatingBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Semantics(
        container: true,
        label: 'Main navigation',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sheet + 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 72,
              decoration: AppShadows.glass(opacity: 0.88).copyWith(
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: List.generate(items.length, (index) {
                  final isActive = index == currentIndex;
                  final item = items[index];
                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: isActive,
                      label: item.label,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onTap(index),
                          borderRadius:
                              BorderRadius.circular(AppRadius.control),
                          child: AppPressEffect(
                            pressedScale: 0.94,
                            child: Center(
                              child: AnimatedContainer(
                                duration: AppMotion.duration(
                                    context, AppMotion.standard),
                                curve: AppMotion.enter,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: AppSpacing.xs + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.secondary
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.control),
                                  boxShadow: isActive
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x24536DFE),
                                            offset: Offset(0, 5),
                                            blurRadius: 10,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: AnimatedSwitcher(
                                  duration: AppMotion.duration(
                                    context,
                                    AppMotion.quick,
                                  ),
                                  switchInCurve: AppMotion.enter,
                                  switchOutCurve: AppMotion.exit,
                                  child: Column(
                                    key: ValueKey(isActive),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isActive ? item.activeIcon : item.icon,
                                        color: isActive
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        size: 20,
                                      ),
                                      const SizedBox(height: 2),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          item.label,
                                          maxLines: 1,
                                          style: AppTypography.caption.copyWith(
                                            color: isActive
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(
  name: 'Bottom navigation',
  group: 'Navigation',
  size: Size(390, 130),
)
Widget floatingBottomNavPreview() => MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: FloatingBottomNav(
          currentIndex: 0,
          onTap: (_) {},
          items: const [
            NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
            ),
            NavItem(
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month_rounded,
              label: 'Gigs',
            ),
            NavItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: 'Orders',
            ),
            NavItem(
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart_rounded,
              label: 'Earnings',
            ),
            NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
