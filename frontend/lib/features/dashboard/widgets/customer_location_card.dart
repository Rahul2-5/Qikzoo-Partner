import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'map_preview.dart';

class CustomerLocationCard extends StatelessWidget {
  final String title;
  final String address;
  final String? pincode;
  final String? etaLine;

  const CustomerLocationCard({
    super.key,
    required this.title,
    required this.address,
    this.pincode,
    this.etaLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.mapPin, color: AppColors.success, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      pincode == null ? address : '$address $pincode',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _NavigateButton(onPressed: () {}),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const MapPreview(height: 150),
          if (etaLine != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(LucideIcons.map, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(etaLine!, style: AppTypography.bodyMedium),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NavigateButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _NavigateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(LucideIcons.navigation, size: 16),
      label: const Text('Navigate'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control)),
      ),
    );
  }
}
