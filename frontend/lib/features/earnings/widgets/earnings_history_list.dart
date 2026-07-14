import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/earnings/earnings_models.dart';
import '../../../shared/widgets/chips/status_chip.dart';

class EarningsHistoryList extends StatelessWidget {
  final List<EarningsHistoryEntry> history;
  final VoidCallback? onViewAll;

  const EarningsHistoryList({super.key, required this.history, this.onViewAll});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.control),
          boxShadow: AppShadows.control,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final viewAll = GestureDetector(
                onTap: onViewAll,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('View All',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.primary)),
                  const Icon(LucideIcons.chevronRight,
                      size: 16, color: AppColors.primary),
                ]),
              );
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Earnings History', style: AppTypography.h2),
                    const SizedBox(height: AppSpacing.xs),
                    Align(alignment: Alignment.centerRight, child: viewAll),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Earnings History', style: AppTypography.h2),
                  viewAll,
                ],
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < history.length; i++) ...[
              if (i > 0)
                const Divider(height: AppSpacing.lg, color: AppColors.border),
              _HistoryRow(entry: history[i]),
            ],
          ],
        ),
      );
}

class _HistoryRow extends StatelessWidget {
  final EarningsHistoryEntry entry;
  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: const Icon(LucideIcons.calendarCheck,
              size: 18, color: AppColors.success),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.dateRange, style: AppTypography.bodyMedium),
              Text(entry.relativeLabel, style: AppTypography.caption),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(CurrencyFormatter.rupeesPrecise(entry.amount),
            style: AppTypography.bodyMedium),
        const SizedBox(width: AppSpacing.sm),
        StatusChip(
          label: entry.paid ? 'Paid' : 'Pending',
          color: entry.paid ? AppColors.success : AppColors.warning,
          background: entry.paid ? AppColors.successBg : AppColors.warningBg,
        ),
      ]);
}
