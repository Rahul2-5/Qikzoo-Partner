import 'package:flutter/material.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const StatusChip({super.key, required this.label, required this.color, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
