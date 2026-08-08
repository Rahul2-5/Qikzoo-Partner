import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/profile/profile_summary.dart';
import '../../../shared/widgets/misc/cached_avatar.dart';

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
    required this.partnerName,
  });

  final int notificationCount;
  final VoidCallback onNotifications;
  final String partnerName;

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
                    color: AppColors.primaryDark,
                    fontStyle: FontStyle.italic,
                    fontSize: 27,
                    letterSpacing: -1.4,
                  ),
                ),
                Text(
                  'PARTNER',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.8,
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
                icon: const Icon(LucideIcons.bell, size: 25),
              ),
              if (notificationCount > 0)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: 19,
                    height: 19,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$notificationCount',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .12),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  _initials(partnerName),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 18,
                  ),
                ),
              ),
              Positioned(
                right: 1,
                bottom: 2,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
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
        builder: (context, constraints) {
          // On phones, putting the cards side by side leaves both the profile
          // details and earnings summary too cramped to scan comfortably.
          final stacked = constraints.maxWidth < 420;
          final compact = !stacked && constraints.maxWidth < 520;
          final identity = _IdentityCard(
            summary: summary,
            onTap: onTap,
            compact: compact,
          );
          final earnings = _EarningsSummary(summary: summary);
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 12), earnings],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 11, child: identity),
                const SizedBox(width: 12),
                Expanded(flex: 9, child: earnings),
              ],
            ),
          );
        },
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

class _EarningsSummary extends StatelessWidget {
  const _EarningsSummary({required this.summary});

  final ProfileSummary summary;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 238,
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 16, 8, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.successBg, AppColors.accentBg],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.success.withValues(alpha: .14)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -13,
                child: Image.asset(
                  AppAssets.profileEarningsWallet3d,
                  width: 105,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("Today's Earnings",
                          style:
                              AppTypography.bodyMedium.copyWith(fontSize: 13)),
                      const SizedBox(width: 5),
                      const Icon(LucideIcons.info,
                          size: 15, color: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    CurrencyFormatter.rupees(summary.pendingAmount),
                    style: AppTypography.numericLg
                        .copyWith(color: AppColors.success, fontSize: 30),
                  ),
                  const Spacer(),
                  Container(
                      height: 1,
                      color: AppColors.success.withValues(alpha: .18)),
                  const SizedBox(height: 9),
                  Text('This Week',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        CurrencyFormatter.rupees(summary.walletBalance),
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.success, fontSize: 18),
                      ),
                      const Spacer(),
                      Container(
                        width: 35,
                        height: 35,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: AppColors.successBg, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.arrowRight,
                            color: AppColors.success, size: 19),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class PartnerStoreCard extends StatelessWidget {
  const PartnerStoreCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 150,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.ctaGradient),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Image.asset(
                    AppAssets.profileStorefront3d,
                    width: 78,
                    fit: BoxFit.contain,
                    semanticLabel: 'Storefront',
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Store',
                            style: AppTypography.body
                                .copyWith(color: AppColors.onPrimary)),
                        const SizedBox(height: 5),
                        Text('Super Store Mumbai',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h2.copyWith(
                                color: AppColors.onPrimary, fontSize: 19)),
                        const SizedBox(height: 7),
                        Row(children: [
                          const Icon(LucideIcons.mapPin,
                              color: AppColors.onPrimary, size: 17),
                          const SizedBox(width: 5),
                          Expanded(
                              child: Text('Kamranwar Nagar, ES1de, Mumbai',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                      color: AppColors.onPrimary
                                          .withValues(alpha: .88)))),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 10),
                    decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.all(Radius.circular(24))),
                    child: const Icon(LucideIcons.chevronRight,
                        color: AppColors.primary, size: 22),
                  ),
                ],
              ),
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
            constraints: const BoxConstraints.tightFor(height: 184),
            padding: const EdgeInsets.fromLTRB(7, 13, 7, 10),
            decoration: BoxDecoration(
              border:
                  Border.all(color: AppColors.border.withValues(alpha: .45)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 65,
                  height: 65,
                  child: assetPath == null
                      ? Icon(icon, color: iconColor, size: 30)
                      : Image.asset(assetPath!,
                          fit: BoxFit.contain, excludeFromSemantics: true),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium
                      .copyWith(fontSize: 13, height: 1.2),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption
                        .copyWith(fontSize: 11, height: 1.2),
                  ),
                ],
                const SizedBox(height: 9),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: .12),
                      shape: BoxShape.circle),
                  child: Icon(LucideIcons.chevronRight,
                      color: iconColor, size: 18),
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
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14)),
            child: assetPath == null
                ? Icon(icon, size: 24, color: color)
                : Image.asset(assetPath!,
                    width: 45,
                    height: 45,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 16),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary),
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
                  color: AppColors.textSecondary, size: 22),
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
