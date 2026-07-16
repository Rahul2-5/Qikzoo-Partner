import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class FeatureHighlightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const FeatureHighlightChip({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label.replaceAll('\n', ' '),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 106),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
          boxShadow: AppShadows.control,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
