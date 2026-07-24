import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/earnings/earnings_models.dart';
import 'delta_chip.dart';

class EarningsBreakdownGrid extends StatelessWidget {
  final List<EarningsCategory> categories;

  const EarningsBreakdownGrid({super.key, required this.categories});

  static const _icons = [
    LucideIcons.bike,
    LucideIcons.gift,
    LucideIcons.mapPin,
    LucideIcons.circleDollarSign,
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < categories.length; i++)
                SizedBox(
                  width: cellWidth,
                  child: _Cell(
                    category: categories[i],
                    icon: _icons[i % _icons.length],
                  ),
                ),
            ],
          );
        },
      );
}

class _Cell extends StatelessWidget {
  final EarningsCategory category;
  final IconData icon;

  const _Cell({required this.category, required this.icon});

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
            Row(children: [
              Icon(icon, size: 18, color: AppColors.secondary),
              const Spacer(),
              DeltaChip(percent: category.deltaPercent, compact: true),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Text(CurrencyFormatter.rupeesPrecise(category.amount),
                style: AppTypography.numericMd),
            const SizedBox(height: 2),
            Text(category.label,
                style: AppTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}
