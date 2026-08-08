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

/// A calm, actionable state for empty lists and unavailable content.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = LucideIcons.inbox,
    required this.message,
    this.title = 'Nothing here yet',
    this.actionLabel,
    this.onAction,
  }) : assert(actionLabel == null || onAction != null);

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
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Icon(icon, size: 32, color: AppColors.primary),
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
                  if (actionLabel != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    SecondaryButton(label: actionLabel!, onPressed: onAction),
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

void previewEmptyStateAction() {}

@Preview(
  name: 'Empty content state',
  group: 'Feedback',
  size: Size(390, 360),
)
Widget emptyStatePreview() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(
        body: EmptyState(
          icon: LucideIcons.packageSearch,
          title: 'No delivery offers yet',
          message: 'New offers will appear here when they are available.',
          actionLabel: 'Refresh',
          onAction: previewEmptyStateAction,
        ),
      ),
    );
