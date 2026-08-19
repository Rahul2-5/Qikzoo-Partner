import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

enum AppSnackBarType { info, success, warning, error }

/// Unified app-wide bottom floating snackbar with consistent semantic colors,
/// rounded margins, and typography across all screens.
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
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: duration,
          backgroundColor: _backgroundColor(type),
          content: Row(
            children: [
              Icon(_icon(type), color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
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

  /// Global bottom snackbar that does not require a BuildContext.
  static void showGlobal({
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.rawSnackbar(
      messageText: Row(
        children: [
          Icon(_icon(type), color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _backgroundColor(type),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderRadius: 12,
      duration: duration,
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

  static Color _backgroundColor(AppSnackBarType type) {
    return switch (type) {
      AppSnackBarType.info => AppColors.primary,
      AppSnackBarType.success => AppColors.success,
      AppSnackBarType.warning => const Color(0xFFF59E0B),
      AppSnackBarType.error => AppColors.error,
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
