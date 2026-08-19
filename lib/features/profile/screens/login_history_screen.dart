import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';

class LoginHistoryScreen extends StatelessWidget {
  const LoginHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Login History'),
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
              // Top highlighted card: TODAY SO FAR
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY SO FAR',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '4h 32m',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'PlusJakartaSans',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Online Time',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Active Now',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Past login details section
              Text(
                'Past login details',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildHistoryWeekItem(
                      weekLabel: 'This Week',
                      dateRange: '17 Aug - 23 Aug',
                      hours: '28h 15m',
                      onTap: () => _showWeekBreakdown(context, 'This Week'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildHistoryWeekItem(
                      weekLabel: 'Previous Week',
                      dateRange: '10 Aug - 16 Aug',
                      hours: '42h 08m',
                      onTap: () => _showWeekBreakdown(context, 'Previous Week'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildHistoryWeekItem(
                      weekLabel: 'Week N - 1',
                      dateRange: '03 Aug - 09 Aug',
                      hours: '39h 45m',
                      onTap: () => _showWeekBreakdown(context, 'Week N - 1'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryWeekItem({
    required String weekLabel,
    required String dateRange,
    required String hours,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weekLabel,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateRange,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    hours,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeekBreakdown(BuildContext context, String weekName) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$weekName Daily Breakdown',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              _buildDayHoursRow('Mon', '6h 12m'),
              _buildDayHoursRow('Tue', '5h 45m'),
              _buildDayHoursRow('Wed', '7h 05m'),
              _buildDayHoursRow('Thu', '4h 20m'),
              _buildDayHoursRow('Fri', '5h 30m'),
              _buildDayHoursRow('Sat', '0h 0m (Off)'),
              _buildDayHoursRow('Sun', '0h 0m (Off)'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayHoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: AppTypography.bodyMedium),
          Text(
            hours,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
