import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class LoadingSkeleton extends StatelessWidget {
  final double height;
  final double? width;

  const LoadingSkeleton({super.key, this.height = 16, this.width});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.textSecondary.withValues(alpha: 0.15),
      highlightColor: AppColors.textSecondary.withValues(alpha: 0.05),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    );
  }
}
