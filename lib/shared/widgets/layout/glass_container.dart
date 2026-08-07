import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/glass_theme.dart';

/// A reusable, performance-conscious glass surface.
///
/// Set [blur] only for short-lived or floating UI. Standard cards deliberately
/// use the same translucent surface without a backdrop filter so long lists
/// remain inexpensive to scroll.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final BorderRadius? borderRadius;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final bool blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.borderRadius,
    this.color,
    this.boxShadow,
    this.blur = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.card);
    final surface = Container(
      width: width,
      height: height,
      alignment: alignment,
      margin: margin,
      padding: padding,
      decoration: blur
          ? GlassTheme.floating(
              borderRadius: radius,
              color: color,
              boxShadow: boxShadow,
            )
          : GlassTheme.surface(
              borderRadius: radius,
              color: color,
              boxShadow: boxShadow,
            ),
      child: child,
    );

    if (!blur) return surface;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassTheme.blurSigma,
          sigmaY: GlassTheme.blurSigma,
        ),
        child: surface,
      ),
    );
  }
}

class GlassDialog extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassDialog({
    super.key,
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassContainer(
          blur: true,
          borderRadius: BorderRadius.circular(22),
          boxShadow: GlassTheme.floatingShadow,
          padding: padding,
          child: child,
        ),
      );
}

class GlassBottomSheet extends StatelessWidget {
  final Widget child;

  const GlassBottomSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) => GlassContainer(
        blur: true,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: GlassTheme.floatingShadow,
        child: child,
      );
}
