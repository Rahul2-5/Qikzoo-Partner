import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'selection_radio.dart';

class CurrentLocationTile extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const CurrentLocationTile({
    super.key,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.secondaryBg,
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.secondary,
                      ),
                    )
                  : const Icon(
                      LucideIcons.locateFixed,
                      color: AppColors.secondary,
                      size: 20,
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Location', style: AppTypography.bodyMedium),
                  Text(
                    isLoading
                        ? 'Detecting your location...'
                        : 'Use my current location',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SelectionRadio(selected: false),
          ],
        ),
      ),
    );
  }
}
