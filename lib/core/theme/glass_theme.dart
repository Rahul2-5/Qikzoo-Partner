import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

/// Shared visual tokens for lightweight, light-theme glass surfaces.
///
/// Most scrolling content uses the translucent treatment without a blur. Blur
/// is reserved for floating elements (navigation, dialogs, and sheets) where
/// it is both more visible and much less expensive to render.
class GlassTheme {
  GlassTheme._();

  static const blurSigma = 10.0;
  static const borderWidth = 1.0;

  static final surfaceColor = AppColors.surface.withValues(alpha: 0.88);
  static final fieldColor = AppColors.surface.withValues(alpha: 0.82);
  static final borderColor = AppColors.border.withValues(alpha: 0.72);
  static const surfaceShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x0D344054),
      offset: Offset(0, 6),
      blurRadius: 18,
    ),
  ];

  static const floatingShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x14344054),
      offset: Offset(0, 10),
      blurRadius: 24,
    ),
  ];

  static BoxDecoration surface({
    BorderRadius? borderRadius,
    Color? color,
    List<BoxShadow>? boxShadow,
  }) =>
      BoxDecoration(
        color: color ?? surfaceColor,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: boxShadow ?? surfaceShadow,
      );

  static BoxDecoration floating({
    BorderRadius? borderRadius,
    Color? color,
    List<BoxShadow>? boxShadow,
  }) =>
      surface(
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.sheet),
        color: color ?? AppColors.surface.withValues(alpha: 0.84),
        boxShadow: boxShadow ?? floatingShadow,
      );

  static final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.button),
    borderSide: BorderSide(color: borderColor),
  );

  static final inputFocusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.button),
    borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
  );
}
