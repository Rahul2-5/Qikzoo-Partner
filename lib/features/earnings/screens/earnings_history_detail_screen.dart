import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';

class OrderEarningDetail {
  final String orderNo;
  final String date;
  final String pickup;
  final String drop;
  final double distance;
  final double basePay;
  final double tip;
  final double total;

  OrderEarningDetail({
    required this.orderNo,
    required this.date,
    required this.pickup,
    required this.drop,
    required this.distance,
    required this.basePay,
    required this.tip,
    required this.total,
  });
}

class EarningsHistoryDetailScreen extends StatelessWidget {
  const EarningsHistoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<OrderEarningDetail> details = [
      OrderEarningDetail(
        orderNo: 'ORD-5491',
        date: '18 Aug, 01:24 PM',
        pickup: 'Noodle House, Bandra',
        drop: 'Carter Road, Bandra West',
        distance: 3.2,
        basePay: 45.0,
        tip: 20.0,
        total: 65.0,
      ),
      OrderEarningDetail(
        orderNo: 'ORD-5388',
        date: '17 Aug, 08:45 PM',
        pickup: 'Pizza Point, Khar',
        drop: 'Linking Road, Santa Cruz',
        distance: 4.5,
        basePay: 55.0,
        tip: 10.0,
        total: 65.0,
      ),
      OrderEarningDetail(
        orderNo: 'ORD-5290',
        date: '17 Aug, 07:15 PM',
        pickup: 'Burger Bistro, Santacruz',
        drop: 'Juhu Scheme, Vile Parle',
        distance: 5.1,
        basePay: 60.0,
        tip: 0.0,
        total: 60.0,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Weekly History Details'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Order-wise Breakdown',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: details.length,
                  itemBuilder: (context, index) {
                    final order = details[index];
                    return _buildOrderDetailCard(order);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailCard(OrderEarningDetail order) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNo,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '₹${order.total.toStringAsFixed(2)}',
                  style: AppTypography.numericMd.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.date,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Route info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.mapPin, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pickup: ${order.pickup}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.navigation, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drop: ${order.drop}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBreakdownItem('Distance', '${order.distance} km'),
                _buildBreakdownItem('Base Fare', '₹${order.basePay.toStringAsFixed(0)}'),
                _buildBreakdownItem('Tip', '₹${order.tip.toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
