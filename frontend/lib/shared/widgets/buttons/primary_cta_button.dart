import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class PrimaryCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final IconData? trailingIcon;

  const PrimaryCtaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final isInteractive = !isLoading && !isDisabled;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: isInteractive ? AppShadows.cta : const [],
        ),
        child: Material(
          color: isDisabled ? AppColors.surfaceMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Ink(
            decoration: isDisabled
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AppColors.border),
                  )
                : BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.ctaGradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.button),
              onTap: isInteractive ? onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (fullWidth)
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.button.copyWith(
                                    color: isDisabled
                                        ? AppColors.textSecondary
                                        : Colors.white,
                                  ),
                                ),
                              )
                            else
                              Text(
                                label,
                                maxLines: 1,
                                style: AppTypography.button.copyWith(
                                  color: isDisabled
                                      ? AppColors.textSecondary
                                      : Colors.white,
                                ),
                              ),
                            if (trailingIcon != null) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Icon(
                                trailingIcon,
                                color: isDisabled
                                    ? AppColors.textSecondary
                                    : Colors.white,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
