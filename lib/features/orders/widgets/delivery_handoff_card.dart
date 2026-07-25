import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Frontend-only handoff guidance displayed once the rider is on the way to
/// the customer. The values are deliberately configurable so API-provided
/// delivery instructions can replace the sample values later without changing
/// the layout.
class DeliveryHandoffCard extends StatelessWidget {
  final String preference;
  final String buildingSummary;
  final String instruction;
  final VoidCallback? onCall;
  final VoidCallback onQuickMessage;
  final VoidCallback onNoResponse;

  const DeliveryHandoffCard({
    super.key,
    required this.preference,
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
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBg,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: const Icon(Icons.handshake_outlined,
                      size: 18, color: AppColors.secondary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Delivery instructions', style: AppTypography.h2),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _InfoChip(icon: Icons.phone_in_talk_outlined, label: preference),
                _InfoChip(icon: Icons.business_outlined, label: buildingSummary),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(instruction, style: AppTypography.body),
            const SizedBox(height: AppSpacing.sm),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
                leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
                title: Text('Building access notes', style: AppTypography.bodyMedium),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Use Gate 2 beside the pharmacy. Two-wheelers can park near the visitor entry. Check with security before using the lift.',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (onCall != null)
                  OutlinedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: const Text('Call'),
                  ),
                OutlinedButton.icon(
                  onPressed: onQuickMessage,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Quick message'),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onNoResponse,
                icon: const Icon(Icons.person_off_outlined, size: 17),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: AppTypography.caption),
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
              buildingSummary: 'Tower B · Gate 2',
              instruction: 'Please hand over to security if unavailable.',
              onQuickMessage: deliveryHandoffPreviewAction,
              onNoResponse: deliveryHandoffPreviewAction,
            ),
          ),
        ),
      ),
    );

void deliveryHandoffPreviewAction() {}
