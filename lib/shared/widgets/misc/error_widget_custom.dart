import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../buttons/secondary_button.dart';
import '../motion/app_motion_widgets.dart';

/// A recoverable, accessible failure state for async content.
class ErrorWidgetCustom extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String title;

  const ErrorWidgetCustom({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'We couldn\'t load this',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $message',
      child: Center(
        child: AppReveal(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: const Icon(
                      LucideIcons.wifiOff,
                      size: 28,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    style: AppTypography.h3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: 148,
                      child: SecondaryButton(
                        label: 'Retry',
                        onPressed: onRetry,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void previewRetry() {}

@Preview(
  name: 'Recoverable error state',
  group: 'Feedback',
  size: Size(390, 360),
)
Widget errorStatePreview() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(
        body: ErrorWidgetCustom(
          message: 'Check your connection and try again.',
          onRetry: previewRetry,
        ),
      ),
    );
