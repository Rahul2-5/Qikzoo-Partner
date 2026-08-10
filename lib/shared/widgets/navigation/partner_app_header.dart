import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

/// Shared application chrome for the partner-facing tab screens.
///
/// It keeps the brand mark, notification treatment, and interactive action
/// sizes identical while allowing each screen to add its own context below it.
class PartnerAppHeader extends StatelessWidget {
  const PartnerAppHeader({
    super.key,
    this.subtitle,
    required this.unreadNotificationCount,
    required this.onNotifications,
    this.trailing,
  });

  final String? subtitle;
  final int unreadNotificationCount;
  final VoidCallback onNotifications;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PartnerNotificationButton(
                unreadCount: unreadNotificationCount,
                onPressed: onNotifications,
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
            ],
          );
          final wordmark = PartnerWordmark(
            subtitle: subtitle,
            compact: compact,
          );

          if (constraints.maxWidth < 300) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                wordmark,
                const SizedBox(height: AppSpacing.xs),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: wordmark),
              actions,
            ],
          );
        },
      );
}

class PartnerWordmark extends StatelessWidget {
  const PartnerWordmark({
    super.key,
    this.subtitle,
    this.compact = false,
  });

  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        label:
            subtitle == null ? 'Qikzoo Partner' : 'Qikzoo Partner, $subtitle',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Qikzoo',
                  style: AppTypography.h2.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    'PARTNER',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontSize: compact ? 7 : 8,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: compact ? 0.6 : 0.8,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      );
}

class PartnerNotificationButton extends StatelessWidget {
  const PartnerNotificationButton({
    super.key,
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: unreadCount > 0
            ? 'Notifications, $unreadCount unread'
            : 'Notifications',
        child: Tooltip(
          message: unreadCount > 0
              ? '$unreadCount unread notifications'
              : 'Notifications',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: Ink(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      LucideIcons.bell,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 2,
                        right: 1,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 17,
                            minHeight: 17,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 8,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class PartnerHeaderIconButton extends StatelessWidget {
  const PartnerHeaderIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: Ink(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, size: 20, color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
      );
}

class PartnerAvatarAction extends StatelessWidget {
  const PartnerAvatarAction({
    super.key,
    required this.initials,
    required this.label,
    required this.onPressed,
    this.isOnline = false,
  });

  final String initials;
  final String label;
  final VoidCallback onPressed;
  final bool isOnline;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14344054),
                            offset: Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        initials.toUpperCase(),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

void previewPartnerNotifications() {}

@Preview(
  name: 'Partner app header',
  group: 'Navigation',
  size: Size(390, 120),
)
Widget partnerAppHeaderPreview() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: PartnerAppHeader(
              subtitle: 'Good morning, Riya',
              unreadNotificationCount: 3,
              onNotifications: previewPartnerNotifications,
              trailing: PartnerAvatarAction(
                initials: 'RK',
                label: 'Riya Kapoor profile',
                onPressed: previewPartnerNotifications,
                isOnline: true,
              ),
            ),
          ),
        ),
      ),
    );
