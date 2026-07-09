import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F1B2559), offset: Offset(0, 8), blurRadius: 24),
    BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 12),
  ];

  static BoxDecoration glass({double opacity = 0.65}) => BoxDecoration(
        color: AppColors.surface.withValues(alpha: opacity),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      );
}
