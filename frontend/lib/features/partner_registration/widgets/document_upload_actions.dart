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

Future<void> pickAndUploadDocument(
  BuildContext context,
  WidgetRef ref,
  DocumentType type,
) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera, color: AppColors.secondary),
              title: Text('Take Photo', style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: AppColors.secondary),
              title: Text('Choose from Gallery', style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null) return;

  final path = await ref.read(documentImagePickerProvider).pickImage(source);
  if (path == null) return;

  try {
    await ref.read(documentsProvider.notifier).upload(type, path);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed, please try again')),
      );
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
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
                  child: const Icon(LucideIcons.fileText, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(LucideIcons.refreshCw, color: AppColors.secondary),
              title: Text('Replace', style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(sheetContext).pop('replace'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: AppColors.error),
              title: Text(
                'Remove',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
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
