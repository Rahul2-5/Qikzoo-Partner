import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/profile/profile_summary.dart';
import '../../../shared/widgets/misc/cached_avatar.dart';
import '../../../shared/widgets/navigation/partner_app_header.dart';

/// Shared visual treatment for the partner profile's raised, airy surfaces.
class PartnerProfileColors {
  PartnerProfileColors._();

  static const green = AppColors.success;
  static const orange = AppColors.accent;
}

class PartnerProfileHeader extends StatelessWidget {
  const PartnerProfileHeader({
    super.key,
    required this.notificationCount,
    required this.onNotifications,
    required this.onProfile,
    required this.partnerName,
  });

  final int notificationCount;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final String partnerName;

  @override
  Widget build(BuildContext context) => PartnerAppHeader(
        subtitle: 'Your partner profile',
        unreadNotificationCount: notificationCount,
        onNotifications: onNotifications,
        trailing: PartnerAvatarAction(
          initials: _initials(partnerName),
          label: '$partnerName profile',
          onPressed: onProfile,
          isOnline: true,
        ),
      );

  static String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join()
      .toUpperCase();
}

class PartnerProfileIdentity extends StatelessWidget {
  const PartnerProfileIdentity({
    super.key,
    required this.summary,
    required this.onTap,
  });

  final ProfileSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => _IdentityCard(
          summary: summary,
          onTap: onTap,
          // Retain the compact treatment only for very small phones. With the
          // earnings panel removed, standard phones have room for the full
          // partner identity rather than a dense side-by-side layout.
          compact: constraints.maxWidth < 360,
        ),
      );
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.summary,
    required this.onTap,
    this.compact = false,
  });

  final ProfileSummary summary;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        elevation: 1.5,
        shadowColor: AppColors.primary.withValues(alpha: .10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 16),
            child: compact ? _compactContent() : _expandedContent(),
          ),
        ),
      );

  Widget _compactContent() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _avatar(radius: 39),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h2.copyWith(fontSize: 16, height: 1.1),
                ),
                const SizedBox(height: 5),
                Text(
                  summary.partnerId.isEmpty
                      ? 'Partner ID unavailable'
                      : summary.partnerId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 15),
                _ratingChip(compact: true),
              ],
            ),
          ),
        ],
      );

  Widget _expandedContent() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(radius: 43),
          const SizedBox(height: 14),
          Text(
            summary.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h2.copyWith(fontSize: 19),
          ),
          const SizedBox(height: 3),
          Text(
            summary.partnerId.isEmpty
                ? 'Partner ID unavailable'
                : summary.partnerId,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          _ratingChip(),
        ],
      );

  Widget _avatar({required double radius}) => Stack(
        clipBehavior: Clip.none,
        children: [
          CachedAvatar(url: summary.photoUrl, radius: radius),
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primarySoft),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: .10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(LucideIcons.camera, size: 18),
            ),
          ),
        ],
      );

  Widget _ratingChip({bool compact = false}) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 10,
          vertical: compact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.star, size: 16, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(summary.ratingAverage.toStringAsFixed(1),
                style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
            if (!compact) ...[
              const SizedBox(width: 8),
              Text('Excellent',
                  style: AppTypography.caption.copyWith(color: AppColors.info)),
            ],
          ],
        ),
      );
}

class PartnerQuickAction extends StatelessWidget {
  const PartnerQuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.onTap,
    this.subtitle,
    this.assetPath,
  });

  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback onTap;
  final String? subtitle;
  final String? assetPath;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            key: const ValueKey('partner-quick-action-card'),
            constraints: const BoxConstraints(minHeight: 128),
            padding: const EdgeInsets.fromLTRB(7, 9, 7, 8),
            decoration: BoxDecoration(
              border:
                  Border.all(color: AppColors.border.withValues(alpha: .45)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: assetPath == null
                      ? Icon(icon, color: iconColor, size: 30)
                      : Image.asset(assetPath!,
                          fit: BoxFit.contain, excludeFromSemantics: true),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium
                      .copyWith(fontSize: 12.5, height: 1.15),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption
                        .copyWith(fontSize: 10.5, height: 1.15),
                  ),
                ],
                const SizedBox(height: 5),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: .12),
                      shape: BoxShape.circle),
                  child: Icon(LucideIcons.chevronRight,
                      color: iconColor, size: 17),
                ),
              ],
            ),
          ),
        ),
      );
}

class PartnerProfileMenuTile extends StatelessWidget {
  const PartnerProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.subtitle,
    this.trailing,
    this.assetPath,
    this.grouped = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String? subtitle;
  final Widget? trailing;
  final String? assetPath;
  final bool grouped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      key: const ValueKey('partner-profile-menu-tile'),
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12)),
            child: assetPath == null
                ? Icon(icon, size: 22, color: color)
                : Image.asset(assetPath!,
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 15),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: trailing!,
            )
          else
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.sm),
              child: Icon(LucideIcons.chevronRight,
                  color: AppColors.textSecondary, size: 20),
            ),
        ],
      ),
    );

    if (grouped) {
      return Material(
          color: Colors.transparent,
          child: InkWell(onTap: onTap, child: content));
    }
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border.withValues(alpha: .55)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: content,
        ),
      ),
    );
  }
}

class PartnerProfileMenuGroup extends StatelessWidget {
  const PartnerProfileMenuGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border.withValues(alpha: .42)),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .05),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 80),
                    child: Divider(
                        height: 1,
                        color: AppColors.border.withValues(alpha: .62)),
                  ),
              ],
            ],
          ),
        ),
      );
}
