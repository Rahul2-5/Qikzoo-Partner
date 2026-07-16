import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class VerificationBanner extends StatelessWidget {
  final bool verified;
  final VoidCallback onTap;

  const VerificationBanner({
    super.key,
    required this.verified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.success : AppColors.warning;
    final background = verified ? AppColors.successBg : AppColors.warningBg;
    final title = verified ? 'Documents Verified' : 'Verification pending';
    final subtitle = verified
        ? 'All your documents are verified'
        : 'We are reviewing your documents';

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      shape: BoxShape.circle),
                  child: Icon(LucideIcons.shieldCheck, color: color, size: 21),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style:
                              AppTypography.bodyMedium.copyWith(color: color)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.caption),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(LucideIcons.chevronRight, size: 20, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
