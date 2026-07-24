import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/profile/profile_summary.dart';
import '../../../shared/widgets/misc/cached_avatar.dart';

class ProfileIdentityCard extends StatelessWidget {
  final ProfileSummary summary;
  final VoidCallback onViewStats;

  const ProfileIdentityCard({
    super.key,
    required this.summary,
    required this.onViewStats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedAvatar(url: summary.photoUrl, radius: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.name,
                      style: AppTypography.h2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('Delivery Partner ID: ${summary.partnerId}',
                      style: AppTypography.caption),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      const Icon(LucideIcons.star,
                          size: 15, color: AppColors.accent),
                      Text(summary.ratingAverage.toStringAsFixed(1),
                          style: AppTypography.bodyMedium),
                      Container(width: 1, height: 16, color: AppColors.border),
                      Text(summary.deliveriesLabel,
                          style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton(
            onPressed: onViewStats,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(76, 42),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
            child: Text('View Stats',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
