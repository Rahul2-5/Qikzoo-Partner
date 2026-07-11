import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;

  const PhoneInputField(
      {super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('+91', style: AppTypography.bodyMedium),
                const SizedBox(width: AppSpacing.xs),
                const Icon(LucideIcons.chevronDown,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
          Container(
              width: 1,
              height: 28,
              color: AppColors.textSecondary.withValues(alpha: 0.15)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: AppTypography.bodyMedium.copyWith(letterSpacing: 0.4),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  hintText: '98765 43210',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
