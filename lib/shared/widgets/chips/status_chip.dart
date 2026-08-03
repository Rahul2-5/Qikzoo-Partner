import 'package:flutter/material.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const StatusChip(
      {super.key,
      required this.label,
      required this.color,
      required this.background});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
            width: GlassTheme.borderWidth,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
