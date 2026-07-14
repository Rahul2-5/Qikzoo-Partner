import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/earnings/earnings_models.dart';

class DeltaChip extends StatelessWidget {
  final double percent;
  final bool compact;

  const DeltaChip({super.key, required this.percent, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final direction = _directionFor(percent);
    final (icon, color) = switch (direction) {
      DeltaDirection.up => (LucideIcons.trendingUp, AppColors.success),
      DeltaDirection.down => (LucideIcons.trendingDown, AppColors.error),
      DeltaDirection.flat => (LucideIcons.minus, AppColors.textSecondary),
    };
    final magnitude = percent.abs();
    final text = magnitude == magnitude.roundToDouble()
        ? '${magnitude.toStringAsFixed(0)}%'
        : '${magnitude.toStringAsFixed(1)}%';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 12 : 14, color: color),
        const SizedBox(width: 2),
        Text(text,
            style: (compact ? AppTypography.caption : AppTypography.bodyMedium)
                .copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  static DeltaDirection _directionFor(double percent) {
    if (percent > 0) return DeltaDirection.up;
    if (percent < 0) return DeltaDirection.down;
    return DeltaDirection.flat;
  }
}
