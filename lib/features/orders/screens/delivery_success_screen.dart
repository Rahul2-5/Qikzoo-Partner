import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/delivery_success_model.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';

class DeliverySuccessScreen extends StatefulWidget {
  const DeliverySuccessScreen({super.key, required this.details});

  final DeliverySuccessModel details;

  @override
  State<DeliverySuccessScreen> createState() => _DeliverySuccessScreenState();
}

class _DeliverySuccessScreenState extends State<DeliverySuccessScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Get.offAllNamed(AppRoutes.orders);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 560,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Spacer(),
                AnimatedScale(
                  scale: _visible ? 1 : 0.86,
                  duration: AppMotion.duration(context, AppMotion.emphasized),
                  curve: AppMotion.emphasizedCurve,
                  child: AnimatedOpacity(
                    opacity: _visible ? 1 : 0,
                    duration: AppMotion.duration(context, AppMotion.emphasized),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.packageCheck,
                        color: AppColors.success,
                        size: 44,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Order Delivered',
                  textAlign: TextAlign.center,
                  style: AppTypography.h1,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Delivery completed successfully',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    children: [
                      _SuccessDetailRow(
                        label: 'Order number',
                        value: '#${details.orderNumber}',
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      _SuccessDetailRow(
                        label: 'Customer payment',
                        value: details.paymentStatusLabel,
                        valueColor: AppColors.success,
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      _SuccessDetailRow(
                        label: 'Collected amount',
                        value: CurrencyFormatter.rupees(
                          details.collectedAmountPaise / 100,
                        ),
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      _SuccessDetailRow(
                        label: 'Completed at',
                        value: DateFormat('d MMM yyyy, h:mm a')
                            .format(details.completedAt),
                      ),
                      if (details.riderEarningsPaise != null) ...[
                        const Divider(height: 24, color: AppColors.border),
                        _SuccessDetailRow(
                          label: 'Your earnings',
                          value: CurrencyFormatter.rupees(
                            details.riderEarningsPaise! / 100,
                          ),
                          valueColor: AppColors.success,
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                PrimaryCtaButton(
                  label: 'Back to Active Orders',
                  trailingIcon: LucideIcons.arrowRight,
                  onPressed: () => Get.offAllNamed(AppRoutes.orders),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessDetailRow extends StatelessWidget {
  const _SuccessDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AppTypography.caption)),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(color: valueColor),
          ),
        ),
      ],
    );
  }
}
