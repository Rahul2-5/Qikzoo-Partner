import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/document_verification/document_model.dart';
import '../../../providers/document_verification/documents_provider.dart';
import '../../../repositories/document_verification/document_image_picker.dart';
import '../../../shared/widgets/buttons/outlined_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';

Future<ImageSource?> showImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(LucideIcons.camera, color: AppColors.secondary),
              title: Text('Take Photo', style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(LucideIcons.image, color: AppColors.secondary),
              title:
                  Text('Choose from Gallery', style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> pickAndUploadDocument(
  BuildContext context,
  WidgetRef ref,
  DocumentType type,
) async {
  final source = await showImageSourceSheet(context);
  if (source == null) return;

  final path = await ref.read(documentImagePickerProvider).pickImage(source);
  if (path == null) return;

  try {
    await ref.read(documentsProvider.notifier).upload(type, path);
  } catch (_) {
    if (context.mounted) {
      AppSnackBar.error(context, 'Upload failed, please try again');
    }
  }
}

Future<void> showDocumentPreviewSheet(
  BuildContext context,
  WidgetRef ref,
  DocumentModel document,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: Image.file(
                File(document.fileUrl!),
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 96,
                  height: 96,
                  color: AppColors.surfaceMuted,
                  child: const Icon(LucideIcons.fileText,
                      color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading:
                  const Icon(LucideIcons.refreshCw, color: AppColors.secondary),
              title: Text('Replace', style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(sheetContext).pop('replace'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: AppColors.error),
              title: Text(
                'Remove',
                style:
                    AppTypography.bodyMedium.copyWith(color: AppColors.error),
              ),
              onTap: () => Navigator.of(sheetContext).pop('remove'),
            ),
          ],
        ),
      ),
    ),
  );

  if (action == 'remove') {
    ref.read(documentsProvider.notifier).remove(document.type);
  } else if (action == 'replace' && context.mounted) {
    await pickAndUploadDocument(context, ref, document.type);
  }
}

Future<bool?> showSelfieConfirmSheet(BuildContext context, String path) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.file(
                File(path),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 120,
                  color: AppColors.surfaceMuted,
                  child: const Icon(
                    LucideIcons.userCircle,
                    color: AppColors.textSecondary,
                    size: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButtonCustom(
                    label: 'Retake',
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryCtaButton(
                    label: 'Use Photo',
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Returns true only after the chosen selfie has been uploaded successfully.
/// When [cameraOnly] is true, the rider cannot choose an existing gallery
/// image, which is used for the selfie required to begin a delivery shift.
Future<bool> pickAndConfirmSelfie(
  BuildContext context,
  WidgetRef ref, {
  bool cameraOnly = false,
}) async {
  while (true) {
    if (!context.mounted) return false;
    final source = cameraOnly
        ? ImageSource.camera
        : await showImageSourceSheet(context);
    if (source == null) return false;

    final path = await ref.read(documentImagePickerProvider).pickImage(source);
    if (path == null) return false;

    if (!context.mounted) return false;
    final useThisPhoto = await showSelfieConfirmSheet(context, path);
    if (useThisPhoto == null) return false;
    if (useThisPhoto == false) continue;

    try {
      await ref
          .read(documentsProvider.notifier)
          .upload(DocumentType.profilePhoto, path);
      return true;
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Upload failed, please try again');
      }
      return false;
    }
  }
}
