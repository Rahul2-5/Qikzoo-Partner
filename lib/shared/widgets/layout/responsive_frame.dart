import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class ResponsiveFrame extends StatelessWidget {
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
        final horizontalPadding =
            constraints.maxWidth >= 600 ? AppSpacing.xl : AppSpacing.lg;

        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding ??
                  EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
