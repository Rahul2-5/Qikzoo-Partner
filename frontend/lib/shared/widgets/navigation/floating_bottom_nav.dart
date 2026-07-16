import 'dart:ui';
import 'package:flutter/material.dart';
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
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
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(index),
                      child: AppPressEffect(
                        pressedScale: 0.94,
                        child: Center(
                          child: AnimatedContainer(
                            duration:
                                AppMotion.duration(context, AppMotion.standard),
                            curve: AppMotion.enter,
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  isActive ? AppSpacing.xs : AppSpacing.sm,
                              vertical: AppSpacing.sm,
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
                                        color: Color(0x2412A783),
                                        offset: Offset(0, 5),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: AnimatedSwitcher(
                              duration:
                                  AppMotion.duration(context, AppMotion.quick),
                              switchInCurve: AppMotion.enter,
                              switchOutCurve: AppMotion.exit,
                              child: isActive
                                  ? Icon(
                                      key: const ValueKey('active'),
                                      item.activeIcon,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : Column(
                                      key: const ValueKey('inactive'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item.icon,
                                          color: AppColors.textSecondary,
                                          size: 21,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
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
          ),
        ),
      ),
    );
  }
}
