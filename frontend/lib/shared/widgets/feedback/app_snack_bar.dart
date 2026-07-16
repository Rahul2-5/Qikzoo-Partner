import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

enum AppSnackBarType { info, success, warning, error }

/// App-wide floating snackbar with consistent semantic colors and typography.
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: _backgroundColor(context, type),
          content: Row(
            children: [
              Icon(_icon(type), color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }

  static void info(BuildContext context, String message) =>
      show(context, message: message);

  static void success(BuildContext context, String message) => show(
        context,
        message: message,
        type: AppSnackBarType.success,
      );

  static void warning(BuildContext context, String message) => show(
        context,
        message: message,
        type: AppSnackBarType.warning,
      );

  static void error(BuildContext context, String message) => show(
        context,
        message: message,
        type: AppSnackBarType.error,
      );

  static Color _backgroundColor(
    BuildContext context,
    AppSnackBarType type,
  ) {
    return switch (type) {
      AppSnackBarType.info => Theme.of(context).colorScheme.primary,
      AppSnackBarType.success => AppColors.success,
      AppSnackBarType.warning => Color.alphaBlend(
          AppColors.primary.withValues(alpha: 0.22),
          AppColors.warning,
        ),
      AppSnackBarType.error => Theme.of(context).colorScheme.error,
    };
  }

  static IconData _icon(AppSnackBarType type) {
    return switch (type) {
      AppSnackBarType.info => LucideIcons.info,
      AppSnackBarType.success => LucideIcons.checkCircle2,
      AppSnackBarType.warning => LucideIcons.alertTriangle,
      AppSnackBarType.error => LucideIcons.alertCircle,
    };
  }
}
