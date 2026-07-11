import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class OnlineOfflineSwitch extends StatelessWidget {
  final bool isOnline;
  final void Function(bool) onChanged;

  const OnlineOfflineSwitch({super.key, required this.isOnline, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isOnline),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: (isOnline ? AppColors.success : AppColors.textSecondary).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: isOnline ? AppColors.success : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isOnline ? AppColors.success : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
