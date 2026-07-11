import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class PasswordStrengthBar extends StatelessWidget {
  final int strength;
  final int segments;

  const PasswordStrengthBar(
      {super.key, required this.strength, this.segments = 4});

  Color get _color {
    if (strength >= segments) return AppColors.accent;
    if (strength > 0) return AppColors.secondary;
    return AppColors.textSecondary;
  }

  String get _label {
    if (strength == 0) return '';
    if (strength >= segments) return 'Strong Password';
    if (strength >= (segments / 2).ceil()) return 'Medium Password';
    return 'Weak Password';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(segments, (index) {
            final filled = index < strength;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                    right: index == segments - 1 ? 0 : AppSpacing.xs),
                height: 4,
                decoration: BoxDecoration(
                  color: filled
                      ? _color
                      : AppColors.textSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(_segmentRadius),
                ),
              ),
            );
          }),
        ),
        if (_label.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_label,
              style: AppTypography.caption
                  .copyWith(color: _color, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}

const _segmentRadius = 4.0;
