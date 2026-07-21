import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/misc/app_3d_illustration.dart';

class OfflineHeroCard extends StatelessWidget {
  final VoidCallback onGoOnline;

  const OfflineHeroCard({super.key, required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, Color(0xFFF4F5FF)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.sheet + 2),
        border: Border.all(color: AppColors.surface),
        boxShadow: AppShadows.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 500;
          final message = _OfflineMessage(onGoOnline: onGoOnline);
          const visual = _OfflineVisual();

          if (horizontal) {
            return Row(
              children: [
                visual,
                const SizedBox(width: AppSpacing.xl),
                Expanded(child: message),
              ],
            );
          }

          return Column(
            children: [
              visual,
              const SizedBox(height: AppSpacing.md),
              message,
            ],
          );
        },
      ),
    );
  }
}

class _OfflineVisual extends StatelessWidget {
  const _OfflineVisual();

  @override
  Widget build(BuildContext context) {
    return const App3dIllustration(
      assetPath: AppAssets.partnerStatusOffline3d,
      semanticLabel: 'Delivery status is offline',
      size: 124,
      glowColor: AppColors.primary,
      fallbackIcon: LucideIcons.power,
    );
  }
}

class _OfflineMessage extends StatelessWidget {
  final VoidCallback onGoOnline;

  const _OfflineMessage({required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "You're offline",
          textAlign: TextAlign.center,
          style: AppTypography.h2.copyWith(fontSize: 20),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Go online when you are ready to start receiving delivery requests.',
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
    );
  }
}
