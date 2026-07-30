import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/profile/profile_summary.dart';
import '../../../shared/widgets/misc/cached_avatar.dart';

/// Surface details used only by the partner profile. These intentionally stay
/// restrained so the individual actions remain easy to scan at a glance.
class PartnerProfileColors {
  PartnerProfileColors._();

  static const border = Color(0xFFE8EAF0);
  static const storeBackground = Color(0xFFF0F4FF);
  static const earningsBackground = Color(0xFFEAF8EF);
  static const green = Color(0xFF159447);
}

class PartnerProfileHeader extends StatelessWidget {
  const PartnerProfileHeader({
    super.key,
    required this.notificationCount,
    required this.onNotifications,
  });

  final int notificationCount;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Semantics(
            label: 'Qikzoo Partner',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qikzoo',
                  style: AppTypography.h1.copyWith(
                    color: const Color(0xFF071B48),
                    fontStyle: FontStyle.italic,
                    letterSpacing: -1.1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 43),
                  child: Text(
                    'PARTNER',
                    style: AppTypography.caption.copyWith(
                      color: PartnerProfileColors.green,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: onNotifications,
                icon: const Icon(
                  LucideIcons.bell,
                  color: AppColors.textPrimary,
                  size: 25,
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 7,
                  top: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
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
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 380;
          final profile = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CachedAvatar(
                      url: summary.photoUrl, radius: compact ? 43 : 48),
                  Positioned(
                    right: -4,
                    bottom: -2,
                    child: Material(
                      color: AppColors.surface,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        onTap: onTap,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(LucideIcons.camera, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 13),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h2
                          .copyWith(fontSize: compact ? 18 : 21),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      summary.partnerId.isEmpty
                          ? 'Partner ID unavailable'
                          : summary.partnerId,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.star,
                              size: 16, color: AppColors.textPrimary),
                          const SizedBox(width: 5),
                          Text(
                            summary.ratingAverage.toStringAsFixed(1),
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final earnings = _EarningsSummary(summary: summary);
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    profile,
                    const SizedBox(height: AppSpacing.md),
                    earnings
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: profile),
                    const SizedBox(width: 12),
                    earnings
                  ],
                );
        },
      );
}

class _EarningsSummary extends StatelessWidget {
  const _EarningsSummary({required this.summary});

  final ProfileSummary summary;

  @override
  Widget build(BuildContext context) => Container(
        width: 174,
        padding: const EdgeInsets.fromLTRB(15, 14, 12, 13),
        decoration: BoxDecoration(
          color: PartnerProfileColors.earningsBackground,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Earnings",
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.rupees(summary.pendingAmount),
                    style: AppTypography.numericMd.copyWith(
                        color: PartnerProfileColors.green, fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  Text('This Week',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 1),
                  Text(CurrencyFormatter.rupees(summary.walletBalance),
                      style: AppTypography.bodyMedium),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                color: PartnerProfileColors.green, size: 21),
          ],
        ),
      );
}

class PartnerStoreCard extends StatelessWidget {
  const PartnerStoreCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: PartnerProfileColors.storeBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      color: Color(0xFF2766DB), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.store,
                      color: Colors.white, size: 25),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Super Store Mumbai',
                          style:
                              AppTypography.bodyMedium.copyWith(fontSize: 15)),
                      const SizedBox(height: 3),
                      Text('Kamranwar Nagar, ES1de, Mumbai',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption),
                    ],
                  ),
                ),
                Text('Go to store',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.info)),
                const SizedBox(width: 3),
                const Icon(LucideIcons.chevronRight,
                    color: AppColors.info, size: 20),
              ],
            ),
          ),
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
  });

  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            constraints: const BoxConstraints(minHeight: 108),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: PartnerProfileColors.border),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 21),
                ),
                const SizedBox(height: 7),
                Text(title,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: PartnerProfileColors.border),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 23, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style:
                              AppTypography.bodyMedium.copyWith(fontSize: 16)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!,
                            style: AppTypography.body
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
                trailing ??
                    const Icon(LucideIcons.chevronRight,
                        color: AppColors.textSecondary, size: 21),
              ],
            ),
          ),
        ),
      );
}
