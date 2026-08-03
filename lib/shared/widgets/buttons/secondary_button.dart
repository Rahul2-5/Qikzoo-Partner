import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../motion/app_motion_widgets.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AppPressEffect(
      enabled: onPressed != null,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              side: BorderSide(color: GlassTheme.borderColor),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
