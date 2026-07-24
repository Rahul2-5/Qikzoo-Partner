import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../buttons/secondary_button.dart';
import '../motion/app_motion_widgets.dart';

class ErrorWidgetCustom extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorWidgetCustom({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppReveal(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 40, color: AppColors.warning),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                style: AppTypography.body, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                  width: 140,
                  child: SecondaryButton(label: 'Retry', onPressed: onRetry)),
            ],
          ],
        ),
      ),
    );
  }
}
