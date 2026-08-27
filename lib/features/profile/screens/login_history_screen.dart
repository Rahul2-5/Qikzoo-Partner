import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/profile/rider_activity_model.dart';
import '../../../repositories/profile/rider_activity_repository.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';

class LoginHistoryScreen extends ConsumerWidget {
  const LoginHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(riderActivityProvider);

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
        child: activity.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoginHistoryMessage(
            icon: LucideIcons.history,
            title: 'Unable to load login history',
            message: error.toString(),
            onRetry: () => ref.invalidate(riderActivityProvider),
          ),
          data: (data) => ResponsiveFrame(
            maxWidth: 520,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                              Text(
                                _duration(data.today.onlineSeconds),
                                style: const TextStyle(
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
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
                      ...data.weeks.take(10).toList().asMap().entries.map(
                        (entry) {
                          final week = entry.value;
                          final label = entry.key == 0
                              ? 'This Week'
                              : entry.key == 1
                                  ? 'Previous Week'
                                  : 'Week ${entry.key + 1}';
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _buildHistoryWeekItem(
                              weekLabel: label,
                              dateRange:
                                  '${_date(week.startDate)} - ${_date(week.endDate)}',
                              hours: _duration(week.onlineSeconds),
                              onTap: () => _showWeekBreakdown(context, week),
                            ),
                          );
                        },
                      ),
                      if (data.weeks.isEmpty)
                        const _LoginHistoryMessage(
                          icon: LucideIcons.calendarClock,
                          title: 'No activity history yet',
                          message: 'Your weekly online time will appear here.',
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Recent login details',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...data.logins.take(10).map(
                            (login) => Card(
                              elevation: 0,
                              margin:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  LucideIcons.logIn,
                                  color: AppColors.primary,
                                ),
                                title: Text(_dateTime(login.createdAt)),
                                subtitle: Text(
                                  login.userAgent ?? 'Mobile app login',
                                ),
                              ),
                            ),
                          ),
                      if (data.logins.isEmpty)
                        const _LoginHistoryMessage(
                          icon: LucideIcons.logIn,
                          title: 'No recent login details',
                          message: 'New app logins will appear here.',
                        ),
                    ],
                  ),
                ),
              ],
            ),
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
              Expanded(
                child: Column(
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
              ),
              const SizedBox(width: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hours,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeekBreakdown(BuildContext context, RiderActivityWeek week) {
    final weekName = '${_date(week.startDate)} - ${_date(week.endDate)}';
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
              ...week.days.map(
                (day) => _buildDayHoursRow(
                  DateFormat('EEE').format(
                    DateTime.tryParse(day.date) ?? DateTime.now(),
                  ),
                  _duration(day.onlineSeconds),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _date(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return '--';
    return DateFormat('d MMM').format(date);
  }

  String _dateTime(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return 'Recent login';
    return DateFormat('d MMM yyyy, h:mm a').format(date.toLocal());
  }

  String _duration(int seconds) =>
      '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';

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

class _LoginHistoryMessage extends StatelessWidget {
  const _LoginHistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 36),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
