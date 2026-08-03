import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'app_bottom_nav.dart';
import 'floating_bottom_nav.dart';

/// Provides one navigation model that adapts to the space available.
///
/// On compact windows it preserves the familiar floating bottom bar. At a
/// tablet-width window it promotes the same five destinations into a labelled
/// rail, leaving the content pane free to use its available width.
class AppTabScaffold extends StatelessWidget {
  const AppTabScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
    this.onDestinationSelected,
  });

  static const tabletNavigationBreakpoint = 720.0;

  final int currentIndex;
  final Widget child;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final onTap = onDestinationSelected ?? navigateToTab;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= tabletNavigationBreakpoint) {
            return Row(
              children: [
                _ExpandedTabRail(
                  currentIndex: currentIndex,
                  onDestinationSelected: onTap,
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.border.withValues(alpha: 0.72),
                ),
                Expanded(child: child),
              ],
            );
          }

          return Column(
            children: [
              Expanded(child: child),
              FloatingBottomNav(
                key: const Key('compact-tab-navigation'),
                currentIndex: currentIndex,
                onTap: onTap,
                items: appTabItems,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExpandedTabRail extends StatelessWidget {
  const _ExpandedTabRail({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('expanded-tab-navigation'),
      width: 232,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Semantics(
              header: true,
              child: Text('Qikzoo Partner', style: AppTypography.h2),
            ),
          ),
          Expanded(
            child: NavigationRail(
              extended: true,
              minExtendedWidth: 232,
              backgroundColor: Colors.transparent,
              selectedIndex: currentIndex,
              labelType: NavigationRailLabelType.none,
              indicatorColor: AppColors.primarySoft,
              selectedIconTheme:
                  const IconThemeData(color: AppColors.primary, size: 22),
              unselectedIconTheme: const IconThemeData(
                color: AppColors.textSecondary,
                size: 22,
              ),
              selectedLabelTextStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
              unselectedLabelTextStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final item in appTabItems)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon),
                    label: Text(item.label),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Partner app',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
