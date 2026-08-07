import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'glass_theme.dart';

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

  /// Deprecated compatibility helper. New glass surfaces should use
  /// [GlassTheme] or [GlassContainer] so they share the same tokens.
  static BoxDecoration glass({double opacity = 0.65}) => GlassTheme.surface(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        color: AppColors.surface.withValues(alpha: opacity),
        boxShadow: const [],
      );
}
