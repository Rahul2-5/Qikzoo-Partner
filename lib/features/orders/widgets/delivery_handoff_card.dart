import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Handoff guidance displayed once the rider is on the way to the customer.
/// Values are rendered from the real order only.
class DeliveryHandoffCard extends StatelessWidget {
  final String? preference;
  final String buildingSummary;
  final String instruction;
  final VoidCallback? onCall;
  final VoidCallback onQuickMessage;
  final VoidCallback onNoResponse;

  const DeliveryHandoffCard({
    super.key,
    this.preference,
    required this.buildingSummary,
    required this.instruction,
    this.onCall,
    required this.onQuickMessage,
    required this.onNoResponse,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: const Icon(
                    LucideIcons.packageCheck,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Delivery instructions',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (preference != null && preference!.trim().isNotEmpty)
                  _InfoChip(
                    icon: LucideIcons.phoneCall,
                    label: preference!.trim(),
                  ),
                if (buildingSummary.trim().isNotEmpty)
                  _InfoChip(
                    icon: LucideIcons.building2,
                    label: buildingSummary.trim(),
                  ),
              ],
            ),
            if (instruction.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                instruction.trim(),
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (onCall != null)
                  OutlinedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(LucideIcons.phoneCall, size: 16),
                    label: const Text('Call'),
                  ),
                OutlinedButton.icon(
                  onPressed: onQuickMessage,
                  icon: const Icon(LucideIcons.messageCircle, size: 16),
                  label: const Text('Quick message'),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onNoResponse,
                icon: const Icon(LucideIcons.userX, size: 15),
                label: const Text('Customer not responding?'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ),
          ],
        ),
      );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: Text(label, style: AppTypography.caption)),
            ],
          ),
        ),
      );
}

@Preview(
  name: 'Customer handoff',
  group: 'Orders',
  size: Size(390, 640),
)
Widget deliveryHandoffCardPreview() => MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: DeliveryHandoffCard(
              preference: 'Call on arrival',
              buildingSummary: 'Tower B - Gate 2',
              instruction: 'Please hand over to security if unavailable.',
              onQuickMessage: deliveryHandoffPreviewAction,
              onNoResponse: deliveryHandoffPreviewAction,
            ),
          ),
        ),
      ),
    );

void deliveryHandoffPreviewAction() {}
