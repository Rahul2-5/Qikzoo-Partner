import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class GreetingHeader extends StatelessWidget {
  final bool online;
  final VoidCallback onToggleStatus;

  const GreetingHeader({
    super.key,
    required this.online,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('QIKZOO',
            style: AppTypography.h2.copyWith(color: AppColors.primary)),
        const Spacer(),
        GestureDetector(
          onTap: onToggleStatus,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              boxShadow: AppShadows.control,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: online ? AppColors.success : AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(online ? 'Online' : 'Offline',
                    style: AppTypography.bodyMedium),
                const Icon(LucideIcons.chevronDown,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          onPressed: () {},
          tooltip: 'Help',
          icon: const Icon(LucideIcons.helpCircle, color: AppColors.primary),
        ),
      ],
    );
  }
}
