import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../buttons/primary_cta_button.dart';
import '../buttons/outlined_button_custom.dart';

class ConfirmationDialog {
  ConfirmationDialog._();

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: AppTypography.body, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButtonCustom(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryCtaButton(
                      label: 'Confirm',
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
