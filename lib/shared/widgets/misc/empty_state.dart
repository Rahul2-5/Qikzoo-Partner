import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../motion/app_motion_widgets.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState(
      {super.key, this.icon = LucideIcons.inbox, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppReveal(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                style: AppTypography.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
