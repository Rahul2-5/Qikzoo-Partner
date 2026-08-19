import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_motion.dart';
import '../motion/app_motion_widgets.dart';

class PrimaryCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final IconData? trailingIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PrimaryCtaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.trailingIcon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;
    final isInteractive = !isLoading && !isDisabled;
    final activeBackground = backgroundColor ?? AppColors.primary;
    final activeForeground = foregroundColor ?? AppColors.onPrimary;

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: isLoading ? '$label, loading' : label,
      child: AppPressEffect(
        enabled: isInteractive,
        child: SizedBox(
          width: fullWidth ? double.infinity : null,
          height: 52,
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
                        color: activeBackground,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  onTap: isInteractive ? onPressed : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: AppMotion.duration(context, AppMotion.quick),
                        switchInCurve: AppMotion.enter,
                        switchOutCurve: AppMotion.exit,
                        child: isLoading
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : Row(
                                key: const ValueKey('label'),
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
                                              ? AppColors.textDisabled
                                              : activeForeground,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      label,
                                      maxLines: 1,
                                      style: AppTypography.button.copyWith(
                                        color: isDisabled
                                            ? AppColors.textDisabled
                                            : activeForeground,
                                      ),
                                    ),
                                  if (trailingIcon != null) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Icon(
                                      trailingIcon,
                                      color: isDisabled
                                          ? AppColors.textDisabled
                                          : activeForeground,
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
          ),
        ),
      ),
    );
  }
}
