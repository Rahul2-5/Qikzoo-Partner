import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/rider_order_model.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/chips/status_chip.dart';

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) =>
      StatusChip(label: label, color: color, background: background);
}

class DeliveryBottomActionBar extends StatelessWidget {
  const DeliveryBottomActionBar({
    super.key,
    required this.paymentVerified,
    required this.proximityReady,
    required this.waitingForGps,
    required this.isLoading,
    required this.onComplete,
  });

  final bool paymentVerified;
  final bool proximityReady;
  final bool waitingForGps;
  final bool isLoading;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final canComplete = paymentVerified && proximityReady && !isLoading;
    final label = !paymentVerified
        ? 'Payment Required'
        : waitingForGps
            ? 'Waiting for Location'
            : !proximityReady
                ? 'Move Closer to Customer'
                : 'Mark as Delivered';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!canComplete && !isLoading) ...[
          Text(
            !paymentVerified
                ? 'Collect and confirm the payment before completing this delivery.'
                : waitingForGps
                    ? 'A fresh GPS location is required to complete delivery.'
                    : 'Delivery completion is available near the customer’s location.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Semantics(
          button: true,
          enabled: canComplete,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              key: const ValueKey('mark-delivered-button'),
              onPressed: canComplete ? onComplete : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.success,
                disabledBackgroundColor: AppColors.surfaceMuted,
                disabledForegroundColor: AppColors.textDisabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Icon(
                      paymentVerified
                          ? LucideIcons.checkCircle2
                          : LucideIcons.lock,
                      size: 19,
                    ),
              label: Text(
                isLoading ? 'Completing Delivery…' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.button.copyWith(
                  color: canComplete || isLoading
                      ? AppColors.onPrimary
                      : AppColors.textDisabled,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OrderPaymentCard extends StatelessWidget {
  const OrderPaymentCard({
    super.key,
    required this.order,
    required this.canOpenCollection,
    this.onCollectPayment,
  });

  final RiderOrderModel order;
  final bool canOpenCollection;
  final VoidCallback? onCollectPayment;

  @override
  Widget build(BuildContext context) {
    final payment = order.order;
    if (payment.isPaidOnline) {
      return _PaidCard(
        badgeLabel: 'PAID ONLINE',
        amountPaise: payment.totalPaise,
        paidAt: payment.paidAt,
        reference: payment.paymentReference,
        icon: LucideIcons.badgeCheck,
      );
    }
    if (payment.isPaidCod) return ConfirmedPaymentCard(order: order);
    if (payment.paymentMethod != OrderPaymentMethod.cod) {
      return const _UnknownPaymentCard();
    }

    final amount = CurrencyFormatter.rupees(payment.totalPaise / 100);
    return Container(
      key: const ValueKey('cod-payment-required-card'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.24),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PaymentStatusBadge(
                      label: 'COD · PAYMENT REQUIRED',
                      color: AppColors.warning,
                      background: AppColors.accentBg,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Amount to collect', style: AppTypography.caption),
                    const SizedBox(height: 2),
                    Text(
                      amount,
                      key: const ValueKey('cod-amount'),
                      style: AppTypography.numericLg.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentBg,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: const Icon(
                  LucideIcons.banknote,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Collect and confirm the payment before completing this delivery.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryCtaButton(
            label: 'Confirm cash $amount',
            trailingIcon: LucideIcons.banknote,
            backgroundColor: AppColors.warning,
            onPressed: canOpenCollection ? onCollectPayment : null,
          ),
          if (!canOpenCollection) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Payment collection becomes available during the delivery step.',
              style: AppTypography.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class ConfirmedPaymentCard extends StatelessWidget {
  const ConfirmedPaymentCard({super.key, required this.order});

  final RiderOrderModel order;

  @override
  Widget build(BuildContext context) {
    return _PaidCard(
      key: const ValueKey('confirmed-payment-card'),
      badgeLabel: 'PAYMENT RECEIVED',
      amountPaise: order.order.totalPaise,
      paidAt: order.order.paidAt,
      reference: order.order.paymentReference,
      icon: LucideIcons.checkCircle2,
    );
  }
}

class _PaidCard extends StatelessWidget {
  const _PaidCard({
    super.key,
    required this.badgeLabel,
    required this.amountPaise,
    required this.paidAt,
    required this.reference,
    required this.icon,
  });

  final String badgeLabel;
  final int amountPaise;
  final DateTime? paidAt;
  final String? reference;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.22),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(icon, color: AppColors.success, size: 23),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PaymentStatusBadge(
                  label: badgeLabel,
                  color: AppColors.success,
                  background: AppColors.successBg,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  CurrencyFormatter.rupees(amountPaise / 100),
                  style: AppTypography.numericMd.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (paidAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Confirmed ${DateFormat('d MMM, h:mm a').format(paidAt!)}',
                    style: AppTypography.caption,
                  ),
                ],
                if (reference != null && reference!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Reference: $reference',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnknownPaymentCard extends StatelessWidget {
  const _UnknownPaymentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.shieldAlert,
            color: AppColors.warning,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PaymentStatusBadge(
                  label: 'PAYMENT STATUS PENDING',
                  color: AppColors.warning,
                  background: AppColors.accentBg,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Refresh the order before collecting payment or completing delivery.',
                  style: AppTypography.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
