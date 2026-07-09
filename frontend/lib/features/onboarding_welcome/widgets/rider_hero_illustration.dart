import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Geometric, on-brand stand-in for a hero illustration — no stock photography
/// or human illustration per the locked design system's empty-state rule.
class RiderHeroIllustration extends StatelessWidget {
  const RiderHeroIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryBg,
            ),
          ),
          const Positioned(
            top: 12,
            left: 24,
            child: _DashedMotionLines(),
          ),
          const Positioned(
            top: 28,
            right: 32,
            child: _RoutePin(),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x1A1B2559), blurRadius: 24, offset: Offset(0, 12)),
              ],
            ),
            child: const Icon(LucideIcons.bike, color: AppColors.primary, size: 64),
          ),
        ],
      ),
    );
  }
}

class _RoutePin extends StatelessWidget {
  const _RoutePin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x33FFB800), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: const Icon(LucideIcons.mapPin, color: AppColors.primary, size: 20),
    );
  }
}

class _DashedMotionLines extends StatelessWidget {
  const _DashedMotionLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.xs, left: (index * 8).toDouble()),
          child: Container(
            width: 28 - (index * 6).toDouble(),
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.5 - (index * 0.1)),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
          ),
        );
      }),
    );
  }
}
