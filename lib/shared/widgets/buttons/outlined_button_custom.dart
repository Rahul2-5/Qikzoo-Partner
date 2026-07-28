import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../motion/app_motion_widgets.dart';

class OutlinedButtonCustom extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const OutlinedButtonCustom({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: AppPressEffect(
        enabled: onPressed != null,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: 1.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              label,
              style: AppTypography.button.copyWith(
                color: onPressed == null
                    ? AppColors.textDisabled
                    : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
