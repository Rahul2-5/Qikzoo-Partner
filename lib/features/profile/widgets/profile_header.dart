import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/navigation/partner_app_header.dart';

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
            const PartnerWordmark(),
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
  Widget build(BuildContext context) => PartnerNotificationButton(
        unreadCount: count,
        onPressed: onPressed,
      );
}
