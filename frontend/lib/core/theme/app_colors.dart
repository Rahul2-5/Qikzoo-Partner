import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1B2559);
  static const secondary = Color(0xFF12A783);
  static const accent = Color(0xFF22C55E);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFE4572E);
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);

  /// CTA gradient (dark teal → bright green), used by PrimaryCtaButton.
  static const ctaGradient = [Color(0xFF0E7A63), Color(0xFF2ECC82)];

  static final successBg = success.withValues(alpha: 0.12);
  static final warningBg = warning.withValues(alpha: 0.12);
  static final secondaryBg = secondary.withValues(alpha: 0.12);
  static final accentBg = accent.withValues(alpha: 0.14);
}
