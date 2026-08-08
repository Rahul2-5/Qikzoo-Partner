import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/glass_theme.dart';

/// A reusable, performance-conscious light surface.
///
/// [blur] is retained for API compatibility and selects the slightly stronger
/// floating-surface elevation; it intentionally does not add backdrop blur.
/// Opaque surfaces keep text and actions crisp over the light app canvas.
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

    return surface;
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
