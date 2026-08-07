import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../motion/app_motion_widgets.dart';
import '../layout/glass_container.dart';

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
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Semantics(
        container: true,
        label: 'Main navigation',
        child: GlassContainer(
          blur: true,
          borderRadius: BorderRadius.circular(AppRadius.sheet + 2),
          boxShadow: GlassTheme.floatingShadow,
          height: 76,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / items.length;

              return Stack(
                children: [
                  AnimatedPositioned(
                    key: const Key('active-navigation-indicator'),
                    duration: AppMotion.duration(context, AppMotion.standard),
                    curve: AppMotion.emphasizedCurve,
                    left: itemWidth * currentIndex + AppSpacing.xs,
                    top: AppSpacing.xs,
                    width: itemWidth - (AppSpacing.xs * 2),
                    height: constraints.maxHeight - (AppSpacing.xs * 2),
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.ctaGradient,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppRadius.control + 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x2E536DFE),
                              offset: Offset(0, 6),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
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
                                  BorderRadius.circular(AppRadius.control + 2),
                              child: AppPressEffect(
                                pressedScale: 0.94,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: AppSpacing.xs + 2,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedScale(
                                          duration: AppMotion.duration(
                                            context,
                                            AppMotion.quick,
                                          ),
                                          curve: AppMotion.enter,
                                          scale: isActive ? 1.1 : 1,
                                          child: AnimatedSwitcher(
                                            duration: AppMotion.duration(
                                              context,
                                              AppMotion.quick,
                                            ),
                                            switchInCurve: AppMotion.enter,
                                            switchOutCurve: AppMotion.exit,
                                            child: Icon(
                                              key: ValueKey(isActive),
                                              isActive
                                                  ? item.activeIcon
                                                  : item.icon,
                                              color: isActive
                                                  ? Colors.white
                                                  : AppColors.textSecondary,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: AnimatedDefaultTextStyle(
                                            duration: AppMotion.duration(
                                              context,
                                              AppMotion.quick,
                                            ),
                                            curve: AppMotion.enter,
                                            style:
                                                AppTypography.caption.copyWith(
                                              color: isActive
                                                  ? Colors.white
                                                  : AppColors.textSecondary,
                                              fontSize: 10.5,
                                              fontWeight: isActive
                                                  ? FontWeight.w800
                                                  : FontWeight.w700,
                                            ),
                                            child:
                                                Text(item.label, maxLines: 1),
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
                      );
                    }),
                  ),
                ],
              );
            },
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
