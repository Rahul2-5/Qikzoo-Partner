import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';

class OnlineSelfieImage extends StatelessWidget {
  const OnlineSelfieImage({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Icon(
          LucideIcons.userCheck,
          size: 72,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}
