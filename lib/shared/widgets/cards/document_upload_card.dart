import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../chips/status_chip.dart';

class DocumentUploadCard extends StatelessWidget {
  final String documentLabel;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final String? rejectionReason;
  final VoidCallback? onTap;

  const DocumentUploadCard({
    super.key,
    required this.documentLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    this.rejectionReason,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Ink(
          decoration: GlassTheme.surface(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(documentLabel, style: AppTypography.bodyMedium),
                    StatusChip(
                        label: statusLabel,
                        color: statusColor,
                        background: statusBackground),
                  ],
                ),
                if (rejectionReason != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(rejectionReason!,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.warning)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
