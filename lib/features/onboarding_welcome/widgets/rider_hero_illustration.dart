import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Branded hero artwork for the welcome screen.
///
/// The transparent hero art sits over an indigo-aware surface so it stays
/// crisp and legible across the welcome flow.
class RiderHeroIllustration extends StatelessWidget {
  final double height;

  const RiderHeroIllustration({super.key, this.height = 244});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Qikzoo delivery partner riding a scooter. '
          'Your next opportunity is closer than you think.',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF9FAFF), Color(0xFFD8DFFF)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.sheet + 6),
          border: Border.all(
            color: AppColors.surface.withValues(alpha: 0.8),
          ),
          boxShadow: AppShadows.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sheet + 6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -72,
                right: -48,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withValues(alpha: 0.13),
                  ),
                ),
              ),
              Positioned(
                left: -42,
                bottom: 26,
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface.withValues(alpha: 0.36),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      AppAssets.riderScooterIndigo3d,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xD42D3436)],
                    stops: [0.54, 1],
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(
                      color: AppColors.surface.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.bike,
                        size: 15,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'RIDE. EARN. GROW.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xB5212C48),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(
                      color: AppColors.surface.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius:
                              BorderRadius.circular(AppRadius.control),
                        ),
                        child: const Icon(
                          LucideIcons.mapPin,
                          color: AppColors.surface,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Expanded(
                        child: Text(
                          'Your next opportunity is closer than you think.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.surface,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
