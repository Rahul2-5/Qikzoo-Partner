import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'selection_radio.dart';

class VehicleTypeCard extends StatelessWidget {
  final String imageAsset;
  final String label;
  final bool selected;
  final bool isPopular;
  final VoidCallback onTap;

  const VehicleTypeCard({
    super.key,
    required this.imageAsset,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.secondaryBg : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Image.asset(
                  imageAsset,
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: AppTypography.bodyMedium.copyWith(fontSize: 16)),
                    if (isPopular) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.star,
                              size: 13, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            'Most popular',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SelectionRadio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}
