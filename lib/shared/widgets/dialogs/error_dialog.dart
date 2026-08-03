import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../layout/glass_container.dart';

class ErrorDialog {
  ErrorDialog._();

  static Future<void> show(BuildContext context, {required String message}) {
    return showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertTriangle,
                color: AppColors.warning, size: 48),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                style: AppTypography.body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
