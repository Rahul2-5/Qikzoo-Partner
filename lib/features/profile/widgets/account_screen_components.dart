import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';

class AccountScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  const AccountScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            IconButtonCustom(
              icon: LucideIcons.arrowLeft,
              onPressed: onBack ?? Get.back,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(title, style: AppTypography.h2)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppTypography.h1.copyWith(fontSize: 26)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class AccountSectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AccountSectionCard({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style: AppTypography.bodyMedium.copyWith(fontSize: 16)),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}

class AccountInfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const AccountInfoBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(message, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
