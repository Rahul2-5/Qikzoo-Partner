import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D344054),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  static const List<BoxShadow> control = [
    BoxShadow(
      color: Color(0x0A344054),
      offset: Offset(0, 4),
      blurRadius: 14,
    ),
  ];

  static const List<BoxShadow> cta = [
    BoxShadow(color: Color(0x33536DFE), offset: Offset(0, 12), blurRadius: 24),
  ];

  static BoxDecoration glass({double opacity = 0.65}) => BoxDecoration(
        color: AppColors.surface.withValues(alpha: opacity),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      );
}
