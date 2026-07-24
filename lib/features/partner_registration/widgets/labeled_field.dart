import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Wraps any field widget with a bold static label above it (rather than a
/// Material floating label), matching this feature's form layout.
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}
