import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class ProfileHeader extends StatelessWidget {
  final int notificationCount;
  final VoidCallback onNotifications;

  const ProfileHeader({
    super.key,
    required this.notificationCount,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The logo text, online pill, and notification button do not fit
        // together on a typical phone once the screen padding is applied.
        final compact = constraints.maxWidth < 400;
        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QIKZOO',
                    style: AppTypography.h2.copyWith(color: AppColors.primary)),
                Text('Delivery Partner', style: AppTypography.caption),
              ],
            ),
            const Spacer(),
            if (!compact) const _OnlinePill(),
            if (!compact) const SizedBox(width: AppSpacing.sm),
            _NotificationButton(
              count: notificationCount,
              onPressed: onNotifications,
            ),
          ],
        );
      },
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        boxShadow: AppShadows.control,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Online', style: AppTypography.bodyMedium),
          const Icon(LucideIcons.chevronDown,
              size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _NotificationButton({required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: count > 0 ? 'Notifications, $count unread' : 'Notifications',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: onPressed,
              tooltip: 'Notifications',
              icon: const Icon(LucideIcons.bell,
                  size: 21, color: AppColors.primary),
            ),
          ),
          if (count > 0)
            Positioned(
              top: 5,
              right: 3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: AppColors.error, shape: BoxShape.circle),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: AppTypography.caption
                      .copyWith(color: Colors.white, fontSize: 10, height: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
