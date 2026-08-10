import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class ResponsiveFrame extends StatelessWidget {
  /// Layout breakpoints are based on the space this frame receives, rather
  /// than a physical device type. This also makes the frame work correctly in
  /// split-screen and resizable windows.
  static const compactBreakpoint = 360.0;
  static const mediumBreakpoint = 600.0;
  static const expandedBreakpoint = 840.0;

  /// The maximum width of the complete frame, including its horizontal
  /// padding. Keeping that contract consistent avoids content jumping between
  /// screens that use different internal layouts.
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveFrame({
    super.key,
    required this.child,
    this.maxWidth = 448,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  /// Returns the standard horizontal gutter for the available content width.
  ///
  /// Callers can still supply [padding] for intentional screen-specific
  /// layouts, but the default keeps the visual rhythm consistent everywhere.
  static double horizontalGutterFor(double availableWidth) {
    if (availableWidth < compactBreakpoint) {
      return AppSpacing.sm + AppSpacing.xs;
    }
    if (availableWidth < mediumBreakpoint) return AppSpacing.md;
    if (availableWidth < expandedBreakpoint) {
      return AppSpacing.md + AppSpacing.xs;
    }
    return AppSpacing.lg;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = horizontalGutterFor(constraints.maxWidth);

        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minWidth: constraints.maxWidth.clamp(0, maxWidth).toDouble(),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: padding ??
                    EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
