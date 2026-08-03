import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../layout/glass_container.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const StatCard(
      {super.key,
      required this.label,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondaryBg,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.numericMd),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
