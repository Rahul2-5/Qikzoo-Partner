import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x121B2559), offset: Offset(0, 10), blurRadius: 28),
  ];

  static const List<BoxShadow> control = [
    BoxShadow(color: Color(0x0A1B2559), offset: Offset(0, 6), blurRadius: 18),
  ];

  static const List<BoxShadow> cta = [
    BoxShadow(color: Color(0x3312A783), offset: Offset(0, 12), blurRadius: 24),
  ];

  static BoxDecoration glass({double opacity = 0.65}) => BoxDecoration(
        color: AppColors.surface.withValues(alpha: opacity),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      );
}
