import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Geometric stand-in for the "documents ready for verification" hero,
/// built entirely from theme tokens (no stock imagery, no red).
class DocumentStackIllustration extends StatelessWidget {
  final double height;

  const DocumentStackIllustration({super.key, this.height = 216});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 300,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 24,
                bottom: 12,
                child: _DocumentCard(
                  width: 140,
                  height: 170,
                  rotation: -0.12,
                  opacity: 0.5,
                ),
              ),
              Positioned(
                right: 40,
                bottom: 4,
                child: _DocumentCard(
                  width: 150,
                  height: 190,
                  rotation: 0.08,
                  opacity: 1,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 56,
                child: _AvatarBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final double width;
  final double height;
  final double rotation;
  final double opacity;

  const _DocumentCard({
    required this.width,
    required this.height,
    required this.rotation,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x141B2559),
                  blurRadius: 20,
                  offset: Offset(0, 10)),
            ],
          ),
          child: opacity == 1
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DocRow(icon: LucideIcons.user, color: AppColors.secondary),
                    SizedBox(height: AppSpacing.sm),
                    _DocRow(
                        icon: LucideIcons.shieldCheck,
                        color: AppColors.primary),
                    SizedBox(height: AppSpacing.sm),
                    _DocRow(
                        icon: LucideIcons.checkCircle2,
                        color: AppColors.success),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _DocRow({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Color(0x3312A783), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: const Icon(LucideIcons.user, color: Colors.white, size: 30),
    );
  }
}
