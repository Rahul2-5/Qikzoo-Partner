import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Brand palette: indigo drives the product's interactive states.
  static const primary = Color(0xFF3F51B5);
  static const primaryDark = Color(0xFF303F9F);
  static const primarySoft = Color(0xFFE8EAF6);
  static const secondary = Color(0xFF536DFE);
  static const secondarySoft = Color(0xFFEEF0FF);
  static const onPrimary = Color(0xFFFFFFFF);

  /// Semantic colors make operational states understandable at a glance.
  static const accent = Color(0xFFFFCA28);
  static const success = Color(0xFF067647);
  static const warning = Color(0xFFB54708);
  static const error = Color(0xFFD14354);
  static const info = Color(0xFF2457BF);

  /// A cool, soft canvas keeps the white surfaces distinct without making
  /// the interface feel boxed in.
  static const background = Color(0xFFF6F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F3F8);

  /// Deliberately quiet so fields, dividers, and unselected controls do not
  /// compete with the content or primary action.
  static const border = Color(0xFFDCE1EB);
  static const textPrimary = Color(0xFF1D2939);
  static const textSecondary = Color(0xFF667085);
  static const textDisabled = Color(0xFF98A2B3);

  /// Indigo depth → electric-indigo lift, used by primary action surfaces.
  static const ctaGradient = [Color(0xFF3F51B5), Color(0xFF536DFE)];

  static final successBg = success.withValues(alpha: 0.12);
  static final warningBg = warning.withValues(alpha: 0.12);
  static const secondaryBg = secondarySoft;
  static const accentBg = Color(0xFFFFF8E1);
}
