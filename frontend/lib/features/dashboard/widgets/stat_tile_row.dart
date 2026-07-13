import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class StatTileRow extends StatelessWidget {
  final int deliveries;
  final String hoursOnline;
  final double rating;

  const StatTileRow({
    super.key,
    required this.deliveries,
    required this.hoursOnline,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _Tile(
                icon: LucideIcons.package,
                value: '$deliveries',
                label: 'Deliveries')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _Tile(
                icon: LucideIcons.clock,
                value: hoursOnline,
                label: 'Online')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _Tile(
                icon: LucideIcons.star,
                value: rating.toStringAsFixed(1),
                label: 'Rating')),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Tile({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.numericMd),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
