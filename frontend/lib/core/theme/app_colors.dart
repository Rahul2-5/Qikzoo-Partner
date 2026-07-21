import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Brand palette: indigo drives every interactive and positive state.
  static const primary = Color(0xFF3F51B5);
  static const primaryDark = Color(0xFF303F9F);
  static const primarySoft = Color(0xFFE8EAF6);
  static const secondary = Color(0xFF536DFE);

  /// Reserved for offers, rewards, and small moments of emphasis.
  static const accent = Color(0xFFFFCA28);
  static const success = Color(0xFF3F51B5);
  static const warning = Color(0xFFB7791F);
  static const error = Color(0xFFD14354);

  static const background = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0F2F7);
  static const border = Color(0xFF607D8B);
  static const textPrimary = Color(0xFF2D3436);
  static const textSecondary = Color(0xFF607D8B);

  /// Indigo depth → electric-indigo lift, used by primary action surfaces.
  static const ctaGradient = [Color(0xFF3F51B5), Color(0xFF536DFE)];

  static final successBg = success.withValues(alpha: 0.12);
  static final warningBg = warning.withValues(alpha: 0.12);
  static final secondaryBg = secondary.withValues(alpha: 0.12);
  static final accentBg = accent.withValues(alpha: 0.14);
}
