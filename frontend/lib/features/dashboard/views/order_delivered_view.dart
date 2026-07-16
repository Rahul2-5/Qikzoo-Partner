import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/order_model.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/misc/earnings_breakdown_widget.dart';
import '../widgets/delivery_success_card.dart';
import '../widgets/incentive_progress_card.dart';
import '../widgets/order_progress_tracker.dart';
import '../widgets/rating_selector.dart';

class OrderDeliveredView extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onContinue;

  const OrderDeliveredView({
    super.key,
    required this.order,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DeliveredHeader(),
        const SizedBox(height: AppSpacing.md),
        const OrderProgressTracker(status: OrderStatus.deliveryConfirmed),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useColumns = constraints.maxWidth >= 760;
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _DeliveredContent(
                  order: order,
                  useColumns: useColumns,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: PrimaryCtaButton(
              label: 'Continue',
              trailingIcon: LucideIcons.arrowRight,
              onPressed: onContinue,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _DeliveredHeader extends StatelessWidget {
  const _DeliveredHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: const Icon(
            LucideIcons.badgeCheck,
            color: AppColors.success,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order delivered',
                style: AppTypography.h1.copyWith(fontSize: 25),
              ),
              Text(
                'Great work — another delivery complete',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeliveredContent extends StatelessWidget {
  final OrderModel order;
  final bool useColumns;

  const _DeliveredContent({required this.order, required this.useColumns});

  @override
  Widget build(BuildContext context) {
    final success = DeliverySuccessCard(
      amount: order.amount,
      timestamp: '11:02 AM · 12 May 2025',
    );
    final breakdown = _EarningsBreakdownCard(order: order);

    if (useColumns) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              children: [
                success,
                const SizedBox(height: AppSpacing.md),
                breakdown,
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          const Expanded(
            flex: 5,
            child: Column(
              children: [
                RatingSelector(),
                SizedBox(height: AppSpacing.md),
                IncentiveProgressCard(
                  completed: 12,
                  target: 20,
                  bonus: 150,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        success,
        const SizedBox(height: AppSpacing.md),
        breakdown,
        const SizedBox(height: AppSpacing.md),
        const RatingSelector(),
        const SizedBox(height: AppSpacing.md),
        const IncentiveProgressCard(
          completed: 12,
          target: 20,
          bonus: 150,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _EarningsBreakdownCard extends StatelessWidget {
  final OrderModel order;

  const _EarningsBreakdownCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: const Icon(
                  LucideIcons.wallet,
                  size: 18,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Text(
                'Earnings breakdown',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          EarningsBreakdownWidget(
            base: order.deliveryFee,
            distance: order.distancePay,
            surge: order.incentive,
            tip: 0,
          ),
        ],
      ),
    );
  }
}
