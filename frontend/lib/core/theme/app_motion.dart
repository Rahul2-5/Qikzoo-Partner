import 'package:flutter/material.dart';

/// Shared motion tokens for consistent, accessible animation across the app.
abstract final class AppMotion {
  static const Duration instant = Duration.zero;
  static const Duration press = Duration(milliseconds: 100);
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration emphasized = Duration(milliseconds: 380);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration ambient = Duration(milliseconds: 1800);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasizedCurve = Curves.easeOutBack;

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration duration(BuildContext context, Duration value) =>
      reduceMotion(context) ? instant : value;
}
