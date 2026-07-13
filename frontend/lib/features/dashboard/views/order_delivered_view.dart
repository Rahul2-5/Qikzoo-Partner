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
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order delivered',
                      style: AppTypography.h1.copyWith(fontSize: 24)),
                  Text('Great job! 🎉',
                      style: AppTypography.body
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OrderProgressTracker(status: OrderStatus.deliveryConfirmed),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DeliverySuccessCard(
                    amount: order.amount,
                    timestamp: '11:02 AM · 12 May 2025'),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    boxShadow: AppShadows.control,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.wallet,
                              size: 18, color: AppColors.success),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Earnings Breakdown',
                              style: AppTypography.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      EarningsBreakdownWidget(
                        base: order.deliveryFee,
                        distance: order.distancePay,
                        surge: order.incentive,
                        tip: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const RatingSelector(),
                const SizedBox(height: AppSpacing.md),
                const IncentiveProgressCard(
                    completed: 12, target: 20, bonus: 150),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryCtaButton(
          label: 'Continue',
          trailingIcon: LucideIcons.arrowRight,
          onPressed: onContinue,
        ),
      ],
    );
  }
}
