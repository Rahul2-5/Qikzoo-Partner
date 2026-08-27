import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/glass_container.dart';

class GoOnlineReadinessDialog {
  const GoOnlineReadinessDialog._();

  static Future<bool?> show(
    BuildContext context, {
    required bool selfieRequired,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.58),
      builder: (dialogContext) => GlassBottomSheet(
        scrollable: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location is required to go online', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Qikzoo Delivery Partner collects your precise location while you are online to match you with nearby delivery requests, track active deliveries, and confirm delivery progress.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _ReadinessStep(
              icon: LucideIcons.mapPin,
              title: 'Live location while online',
              subtitle: 'Required to receive and complete deliveries',
            ),
            if (selfieRequired) ...[
              const SizedBox(height: AppSpacing.sm),
              const _ReadinessStep(
                icon: LucideIcons.scanFace,
                title: 'Live selfie',
                subtitle: 'Required for this shift by Qikzoo verification',
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(
                  LucideIcons.shieldCheck,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'You cannot receive or complete deliveries without location access. Location sharing stops when you go offline.',
                    style: AppTypography.caption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: PrimaryCtaButton(
                label: 'Continue',
                trailingIcon: LucideIcons.arrowRight,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Stay offline'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Policy disclosure shown immediately before requesting Android's
/// "Allow all the time" location permission. It is intentionally separate
/// from the foreground-location disclosure: background collection has a
/// different user expectation and Android presents a separate permission UI.
class BackgroundLocationDisclosureDialog {
  const BackgroundLocationDisclosureDialog._();

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.58),
      builder: (dialogContext) => GlassBottomSheet(
        scrollable: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: const Icon(
                LucideIcons.mapPin,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Keep deliveries active in the background',
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Qikzoo Delivery Partner collects location data to enable '
              'nearby delivery offers, active-delivery tracking, and '
              'delivery progress even when the app is closed or not in use.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Background location is used only while you are online. Go '
              'offline at any time to stop location sharing.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: PrimaryCtaButton(
                label: 'Enable background location',
                trailingIcon: LucideIcons.arrowRight,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Not now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationCheckDialog extends StatelessWidget {
  const LocationCheckDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LocationCheckDialog(
        key: Key('location-check-dialog'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 54,
            height: 54,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Getting your current location', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Keep this screen open while we verify your position.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessStep extends StatelessWidget {
  const _ReadinessStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          const Icon(
            LucideIcons.checkCircle2,
            color: AppColors.success,
            size: 19,
          ),
        ],
      ),
    );
  }
}
