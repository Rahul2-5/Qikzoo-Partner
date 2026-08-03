import 'package:flutter/material.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../layout/glass_container.dart';

class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const GlassButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: true,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
