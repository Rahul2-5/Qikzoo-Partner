import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Atomic loading skeleton placeholder with configurable dimensions and shape.
class LoadingSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const LoadingSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const LoadingSkeleton.circle({
    super.key,
    required double size,
  })  : height = size,
        width = size,
        borderRadius = null,
        shape = BoxShape.circle;

  const LoadingSkeleton.card({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  }) : shape = BoxShape.rectangle;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = shape == BoxShape.circle
        ? null
        : (borderRadius ?? BorderRadius.circular(8));

    final placeholder = Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        shape: shape,
        borderRadius: effectiveRadius,
      ),
    );

    if (AppMotion.reduceMotion(context)) {
      return placeholder;
    }

    return Shimmer.fromColors(
      period: const Duration(milliseconds: 1400),
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: placeholder,
    );
  }
}

/// Generic page shimmer layout with a header panel and content list cards.
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
                Row(
                  children: [
                    const LoadingSkeleton.circle(size: 40),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LoadingSkeleton(
                            height: 16,
                            width: 140,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 6),
                          LoadingSkeleton(
                            height: 12,
                            width: 90,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Container(
                height: 110,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(
                      height: 14,
                      width: 120,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const Spacer(),
                    LoadingSkeleton(
                      height: 24,
                      width: 160,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    LoadingSkeleton(
                      height: 11,
                      width: 200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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

/// Shimmer for Dashboard Home screen matching status banner + 3 overview cards + quick actions.
class DashboardLoadingShimmer extends StatelessWidget {
  const DashboardLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const LoadingSkeleton.circle(size: 42),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingSkeleton(
                        height: 14,
                        width: 110,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 5),
                      LoadingSkeleton(
                        height: 11,
                        width: 70,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
              LoadingSkeleton(
                height: 34,
                width: 90,
                borderRadius: BorderRadius.circular(999),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Online Status Banner
          LoadingSkeleton.card(
            height: 160,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 16),

          // Overview Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LoadingSkeleton(
                height: 16,
                width: 130,
                borderRadius: BorderRadius.circular(4),
              ),
              LoadingSkeleton(
                height: 18,
                width: 65,
                borderRadius: BorderRadius.circular(999),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3 Overview Cards Row
          Row(
            children: [
              Expanded(
                child: LoadingSkeleton.card(
                  height: 130,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LoadingSkeleton.card(
                  height: 130,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LoadingSkeleton.card(
                  height: 130,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Actions Grid Header
          LoadingSkeleton(
            height: 16,
            width: 110,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),

          // 2x2 Action Tiles
          Row(
            children: [
              Expanded(
                child: LoadingSkeleton.card(
                  height: 80,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LoadingSkeleton.card(
                  height: 80,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: LoadingSkeleton.card(
                  height: 80,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LoadingSkeleton.card(
                  height: 80,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer for Wallet screen matching balance card + action buttons + deposit/history.
class WalletLoadingShimmer extends StatelessWidget {
  const WalletLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet Balance Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LoadingSkeleton(
                      height: 13,
                      width: 120,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const LoadingSkeleton.circle(size: 24),
                  ],
                ),
                const SizedBox(height: 12),
                LoadingSkeleton(
                  height: 36,
                  width: 150,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LoadingSkeleton(
                          height: 11,
                          width: 80,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        LoadingSkeleton(
                          height: 16,
                          width: 70,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        LoadingSkeleton(
                          height: 11,
                          width: 80,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        LoadingSkeleton(
                          height: 16,
                          width: 70,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: LoadingSkeleton.card(
                  height: 48,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoadingSkeleton.card(
                  height: 48,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Transactions Header
          LoadingSkeleton(
            height: 16,
            width: 140,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),

          // Transaction Shimmer Rows
          for (var i = 0; i < 4; i++) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const LoadingSkeleton.circle(size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LoadingSkeleton(
                          height: 14,
                          width: 130,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        LoadingSkeleton(
                          height: 11,
                          width: 90,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  LoadingSkeleton(
                    height: 16,
                    width: 60,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// Shimmer for Profile screen matching profile avatar card + shift details + menu options.
class ProfileLoadingShimmer extends StatelessWidget {
  const ProfileLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Profile Avatar Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const LoadingSkeleton.circle(size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingSkeleton(
                        height: 18,
                        width: 140,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      LoadingSkeleton(
                        height: 12,
                        width: 100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      LoadingSkeleton(
                        height: 20,
                        width: 80,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Menu Tiles
          for (var i = 0; i < 5; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const LoadingSkeleton.circle(size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: LoadingSkeleton(
                      height: 14,
                      width: 120,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const LoadingSkeleton.circle(size: 16),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Shimmer for Orders / Delivery History screen matching order cards.
class OrdersLoadingShimmer extends StatelessWidget {
  const OrdersLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LoadingSkeleton(
                        height: 14,
                        width: 90,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      LoadingSkeleton(
                        height: 22,
                        width: 80,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const LoadingSkeleton.circle(size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LoadingSkeleton(
                              height: 14,
                              width: 140,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 6),
                            LoadingSkeleton(
                              height: 11,
                              width: 180,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                      LoadingSkeleton(
                        height: 18,
                        width: 50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ShimmerListItem extends StatelessWidget {
  const _ShimmerListItem();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const LoadingSkeleton.circle(size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(
                    height: 14,
                    width: 150,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  LoadingSkeleton(
                    height: 11,
                    width: 200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
