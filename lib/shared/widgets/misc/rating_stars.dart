import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const RatingStars({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          LucideIcons.star,
          size: size,
          color: index < fullStars ? AppColors.accent : AppColors.textSecondary.withValues(alpha: 0.3),
        );
      }),
    );
  }
}
