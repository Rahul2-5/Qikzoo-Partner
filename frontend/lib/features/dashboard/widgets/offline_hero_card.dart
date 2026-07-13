import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';

class OfflineHeroCard extends StatelessWidget {
  final VoidCallback onGoOnline;

  const OfflineHeroCard({super.key, required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.power,
                color: AppColors.textSecondary, size: 30),
          ),
          const SizedBox(height: AppSpacing.md),
          Text("You're offline", style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Go online to start receiving delivery requests near you.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryCtaButton(
            label: 'Go Online',
            trailingIcon: LucideIcons.arrowRight,
            onPressed: onGoOnline,
          ),
        ],
      ),
    );
  }
}
