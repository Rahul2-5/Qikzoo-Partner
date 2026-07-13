import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class RatingSelector extends StatefulWidget {
  const RatingSelector({super.key});

  @override
  State<RatingSelector> createState() => _RatingSelectorState();
}

class _RatingSelectorState extends State<RatingSelector> {
  static const _labels = ['Very Bad', 'Bad', 'Okay', 'Good', 'Excellent'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How was this delivery experience?',
              style: AppTypography.bodyMedium),
          Text('Your feedback helps us improve', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final filled = i < _selected;
              return Semantics(
                label: 'Rate ${_labels[i]}, ${i + 1} of 5',
                button: true,
                child: GestureDetector(
                  onTap: () => setState(() => _selected = i + 1),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.star,
                        size: 28,
                        color: filled
                            ? AppColors.accent
                            : AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(_labels[i], style: AppTypography.caption),
                    ],
                  ),
                ),
              );
            }),
          ),
          if (_selected > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Thanks for the feedback!',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.success)),
          ],
        ],
      ),
    );
  }
}
