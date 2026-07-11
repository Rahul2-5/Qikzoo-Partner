import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'selection_radio.dart';

class CityListTile extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const CityListTile({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
              child: const Icon(
                LucideIcons.building2,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                name,
                style: AppTypography.bodyMedium,
              ),
            ),
            SelectionRadio(selected: selected),
          ],
        ),
      ),
    );
  }
}

class CityListDivider extends StatelessWidget {
  const CityListDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.border, height: AppSpacing.md);
  }
}
