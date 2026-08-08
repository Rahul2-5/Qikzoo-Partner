import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

/// Shared tokens for light, low-elevation surfaces.
///
/// The legacy name is kept so existing cards and sheets continue to share one
/// visual contract. Content surfaces are deliberately opaque: the app remains
/// calm and readable instead of layering glass effects through every screen.
class GlassTheme {
  GlassTheme._();

  static const blurSigma = 10.0;
  static const borderWidth = 1.0;

  static const surfaceColor = AppColors.surface;
  static const fieldColor = AppColors.surface;
  static const borderColor = AppColors.border;
  static const surfaceShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A344054),
      offset: Offset(0, 4),
      blurRadius: 14,
    ),
  ];

  static const floatingShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x12344054),
      offset: Offset(0, 8),
      blurRadius: 20,
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
        color: color ?? AppColors.surface,
        boxShadow: boxShadow ?? floatingShadow,
      );

  static final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.button),
    borderSide: const BorderSide(color: borderColor),
  );

  static final inputFocusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.button),
    borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
  );
}
