import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class ResponsiveFrame extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = switch (constraints.maxWidth) {
          < 360 => AppSpacing.sm + AppSpacing.xs,
          < 600 => AppSpacing.md,
          _ => AppSpacing.lg,
        };

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
