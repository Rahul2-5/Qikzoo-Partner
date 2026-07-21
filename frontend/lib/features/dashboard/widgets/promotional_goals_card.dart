import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class DeliveryGoal {
  final int deliveries;
  final double reward;

  const DeliveryGoal({
    required this.deliveries,
    required this.reward,
  });
}

class PromotionalGoalsCard extends StatelessWidget {
  final int completedOrders;
  final List<DeliveryGoal> goals;
  final String offerEndsLabel;

  const PromotionalGoalsCard({
    super.key,
    required this.completedOrders,
    required this.goals,
    required this.offerEndsLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return const SizedBox.shrink();

    final sortedGoals = [...goals]
      ..sort((a, b) => a.deliveries.compareTo(b.deliveries));
    final topGoal = sortedGoals.last;
    final safeCompleted = completedOrders.clamp(0, topGoal.deliveries);
    final nextGoal = _nextGoal(sortedGoals);
    final progress = topGoal.deliveries == 0
        ? 0.0
        : (safeCompleted / topGoal.deliveries).clamp(0.0, 1.0);

    final semantics = sortedGoals
        .map(
          (goal) => '${goal.deliveries} deliveries for '
              '${CurrencyFormatter.rupees(goal.reward)} extra',
        )
        .join(', ');

    return Semantics(
      container: true,
      label: 'Promotional weekly delivery goals. $completedOrders orders '
          'completed. $semantics. Offer $offerEndsLabel.',
      excludeSemantics: true,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sheet + 2),
          border: Border.all(
            color: const Color(0xFFF3D8A5).withValues(alpha: 0.85),
          ),
          boxShadow: AppShadows.card,
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -42,
              top: -54,
              child: _DecorativeGlow(size: 150),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OfferHeader(offerEndsLabel: offerEndsLabel),
                  const SizedBox(height: AppSpacing.lg),
                  _RewardHeadline(topReward: topGoal.reward),
                  const SizedBox(height: AppSpacing.lg),
                  _ProgressSummary(
                    completed: safeCompleted,
                    target: topGoal.deliveries,
                    progress: progress,
                    nextGoal: nextGoal,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...sortedGoals.indexed.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.$1 == sortedGoals.length - 1
                            ? 0
                            : AppSpacing.sm,
                      ),
                      child: _GoalMilestone(
                        goal: entry.$2,
                        completedOrders: safeCompleted,
                        isNext: nextGoal == entry.$2,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.info,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Highest milestone reward applies',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DeliveryGoal? _nextGoal(List<DeliveryGoal> sortedGoals) {
    for (final goal in sortedGoals) {
      if (completedOrders < goal.deliveries) return goal;
    }
    return null;
  }
}

class _DecorativeGlow extends StatelessWidget {
  final double size;

  const _DecorativeGlow({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFFC85A).withValues(alpha: 0.24),
            const Color(0xFFFFF7E8).withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _OfferHeader extends StatelessWidget {
  final String offerEndsLabel;

  const _OfferHeader({required this.offerEndsLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFE8B7), Color(0xFFFFC85A)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: const Icon(
            LucideIcons.gift,
            size: 21,
            color: Color(0xFF8A5200),
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly delivery quest',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    LucideIcons.clock3,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      offerEndsLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D6),
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: const Color(0xFFFFD784)),
          ),
          child: Text(
            'PROMO',
            style: AppTypography.caption.copyWith(
              color: const Color(0xFF925600),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardHeadline extends StatelessWidget {
  final double topReward;

  const _RewardHeadline({required this.topReward});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deliver more. Earn more.',
                style: AppTypography.h2.copyWith(fontSize: 19),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Complete a milestone to unlock your bonus.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'UP TO',
              style: AppTypography.caption.copyWith(
                color: AppColors.secondary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            Text(
              CurrencyFormatter.rupees(topReward),
              style: AppTypography.numericLg.copyWith(
                color: AppColors.primary,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'EXTRA',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final int completed;
  final int target;
  final double progress;
  final DeliveryGoal? nextGoal;

  const _ProgressSummary({
    required this.completed,
    required this.target,
    required this.progress,
    required this.nextGoal,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = nextGoal == null
        ? 0
        : (nextGoal!.deliveries - completed).clamp(0, nextGoal!.deliveries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                nextGoal == null
                    ? 'All goals completed'
                    : '$remaining more to unlock ${CurrencyFormatter.rupees(nextGoal!.reward)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: nextGoal == null
                      ? AppColors.success
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$completed / $target',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppColors.surfaceMuted,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalMilestone extends StatelessWidget {
  final DeliveryGoal goal;
  final int completedOrders;
  final bool isNext;

  const _GoalMilestone({
    required this.goal,
    required this.completedOrders,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = completedOrders >= goal.deliveries;
    final foreground = isCompleted
        ? AppColors.success
        : isNext
            ? AppColors.secondary
            : AppColors.textSecondary;
    final background = isCompleted
        ? AppColors.successBg
        : isNext
            ? AppColors.secondaryBg
            : AppColors.surfaceMuted;

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(
          color:
              foreground.withValues(alpha: isNext || isCompleted ? 0.18 : 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: foreground.withValues(alpha: 0.2)),
            ),
            child: Icon(
              isCompleted
                  ? LucideIcons.check
                  : isNext
                      ? LucideIcons.target
                      : LucideIcons.lock,
              size: 18,
              color: foreground,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${goal.deliveries} deliveries',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isCompleted
                      ? 'Milestone completed'
                      : isNext
                          ? '${goal.deliveries - completedOrders} orders to go'
                          : 'Complete the previous goal first',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CurrencyFormatter.rupees(goal.reward),
                style: AppTypography.numericMd.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'EXTRA',
                style: AppTypography.caption.copyWith(
                  color: foreground,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
