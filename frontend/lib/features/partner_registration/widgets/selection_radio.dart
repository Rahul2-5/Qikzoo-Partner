import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';

/// Minimal radio-button visual used by list-style single-select rows
/// (city list, current-location tile) where FilterChipCustom's chip shape
/// doesn't fit.
class SelectionRadio extends StatelessWidget {
  final bool selected;

  const SelectionRadio({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.quick),
      curve: AppMotion.enter,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.secondary : AppColors.border,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
              ),
            )
          : null,
    );
  }
}
