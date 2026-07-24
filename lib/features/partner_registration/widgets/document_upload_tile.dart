import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/document_verification/document_model.dart';

class DocumentUploadTile extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;

  const DocumentUploadTile({
    super.key,
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = document.type;
    final isUploaded = document.status == DocumentStatus.pendingVerification ||
        document.status == DocumentStatus.verified;
    final isUploading = document.status == DocumentStatus.uploading;
    final isRejected = document.status == DocumentStatus.rejected;

    final Color statusColor = isUploaded
        ? AppColors.success
        : isRejected
            ? AppColors.error
            : AppColors.warning;
    final String statusLabel = isUploaded
        ? 'Uploaded'
        : isRejected
            ? 'Rejected'
            : 'Upload';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Icon(type.icon, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: AppTypography.bodyMedium,
                        children: [
                          TextSpan(text: type.label),
                          TextSpan(
                            text: type.isOptional
                                ? '  (Optional)'
                                : '  (Required)',
                            style: AppTypography.caption.copyWith(
                              color: type.isOptional
                                  ? AppColors.textSecondary
                                  : AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    statusLabel,
                    style:
                        AppTypography.bodyMedium.copyWith(color: statusColor),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isUploaded
                              ? LucideIcons.checkCircle2
                              : isRejected
                                  ? LucideIcons.alertTriangle
                                  : LucideIcons.circle,
                          color: statusColor,
                          size: 22,
                        ),
                ],
              ),
              if (isRejected && document.rejectionReason != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  document.rejectionReason!,
                  style:
                      AppTypography.caption.copyWith(color: AppColors.warning),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
