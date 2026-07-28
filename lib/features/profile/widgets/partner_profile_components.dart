import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/profile/profile_summary.dart';
import '../../../shared/widgets/misc/cached_avatar.dart';

/// Profile-only colors that extend, rather than replace, the application
/// palette. Keeping them here lets this layout retain the Qikzoo look.
class PartnerProfileColors {
  PartnerProfileColors._();

  static const cardBorder = Color(0xFFE4E7EC);
  static const quietSurface = Color(0xFFF9FAFB);
}

class PartnerProfileHeader extends StatelessWidget {
  const PartnerProfileHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(LucideIcons.arrowLeft),
        ),
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
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: PartnerProfileColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              summary.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.h2.copyWith(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.chevronRight, size: 21),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.partnerId,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CachedAvatar(url: summary.photoUrl, radius: 38),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: PartnerProfileColors.cardBorder),
                        ),
                        child: const Icon(LucideIcons.camera, size: 16),
                      ),
                    ),
                  ],
                ),
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Ink(
            height: 92,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: PartnerProfileColors.cardBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(height: 8),
                Text(title, style: AppTypography.bodyMedium.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ),
      );
}

class PartnerReferralCard extends StatelessWidget {
  const PartnerReferralCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Ink(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Up to ₹2,000 referral bonus', style: AppTypography.bodyMedium),
                      const SizedBox(height: 2),
                      Text('Refer your friend and earn', style: AppTypography.caption),
                    ],
                  ),
                ),
                const Icon(LucideIcons.indianRupee,
                    color: AppColors.accent, size: 36),
              ],
            ),
          ),
        ),
      );
}

class PartnerProfileSectionItem {
  const PartnerProfileSectionItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}

class PartnerProfileSection extends StatelessWidget {
  const PartnerProfileSection({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<PartnerProfileSectionItem> items;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: PartnerProfileColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Text(title, style: AppTypography.bodyMedium),
            ),
            for (var index = 0; index < items.length; index++) ...[
              _PartnerProfileSectionTile(item: items[index]),
              if (index < items.length - 1)
                const Divider(height: 1, indent: 50, color: PartnerProfileColors.cardBorder),
            ],
          ],
        ),
      );
}

class _PartnerProfileSectionTile extends StatelessWidget {
  const _PartnerProfileSectionTile({required this.item});

  final PartnerProfileSectionItem item;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: item.title,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(item.icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 14),
                  Expanded(child: Text(item.title, style: AppTypography.body)),
                  const Icon(LucideIcons.chevronRight,
                      size: 20, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      );
}
