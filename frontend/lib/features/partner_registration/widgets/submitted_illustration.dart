import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class SubmittedIllustration extends StatelessWidget {
  const SubmittedIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _dot(top: 10, left: 20, color: AppColors.secondary, size: 8),
          _dot(top: 30, left: 60, color: AppColors.accent, size: 6),
          _dot(top: 20, right: 20, color: AppColors.secondary, size: 8),
          _dot(top: 40, right: 55, color: AppColors.warning, size: 6),
          _dot(bottom: 30, left: 10, color: AppColors.warning, size: 8),
          _dot(bottom: 15, right: 15, color: AppColors.accent, size: 8),
          Container(
            width: 140,
            height: 190,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.secondary, width: 2),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.check, size: 10, color: AppColors.success),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            child: Container(
              width: 44,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.check, size: 26, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
