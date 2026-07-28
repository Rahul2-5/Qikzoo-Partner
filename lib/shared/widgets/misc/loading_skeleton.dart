import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class LoadingSkeleton extends StatelessWidget {
  final double height;
  final double? width;

  const LoadingSkeleton({super.key, this.height = 16, this.width});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    );
    if (AppMotion.reduceMotion(context)) {
      return placeholder;
    }

    return Shimmer.fromColors(
      period: AppMotion.ambient,
      baseColor: AppColors.textSecondary.withValues(alpha: 0.15),
      highlightColor: AppColors.textSecondary.withValues(alpha: 0.05),
      child: placeholder,
    );
  }
}

/// A responsive, content-shaped placeholder for full-screen data loads.
/// It avoids a blocking spinner while preserving the page's visual rhythm.
class PageLoadingShimmer extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final int itemCount;
  final bool showHeader;

  const PageLoadingShimmer({
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.itemCount = 3,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading content',
      child: ExcludeSemantics(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) ...[
                const Row(
                  children: [
                    LoadingSkeleton(height: 44, width: 44),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(child: LoadingSkeleton(height: 18, width: 160)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              const _ShimmerPanel(height: 126),
              const SizedBox(height: AppSpacing.lg),
              for (var index = 0; index < itemCount; index++) ...[
                const _ShimmerListItem(),
                if (index < itemCount - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerPanel extends StatelessWidget {
  final double height;

  const _ShimmerPanel({required this.height});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            height: height - (AppSpacing.md * 2),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(height: 14, width: 120),
                Spacer(),
                LoadingSkeleton(height: 30, width: 180),
                SizedBox(height: AppSpacing.sm),
                LoadingSkeleton(height: 12, width: 230),
              ],
            ),
          ),
        ),
      );
}

class _ShimmerListItem extends StatelessWidget {
  const _ShimmerListItem();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              LoadingSkeleton(height: 44, width: 44),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 15, width: 160),
                    SizedBox(height: AppSpacing.sm),
                    LoadingSkeleton(height: 12, width: 220),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
