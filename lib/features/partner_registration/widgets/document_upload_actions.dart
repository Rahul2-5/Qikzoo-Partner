import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/document_verification/document_model.dart';
import '../../../providers/core/camera_config_provider.dart';
import '../../../providers/document_verification/documents_provider.dart';
import '../../../repositories/document_verification/document_image_picker.dart';
import '../../../repositories/profile/profile_repository.dart';
import '../../../shared/widgets/buttons/outlined_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/glass_container.dart';
import '../screens/selfie_camera_capture_screen.dart';

Future<ImageSource?> showImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => GlassBottomSheet(
      child: SafeArea(
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
                title: Text('Choose from Gallery',
                    style: AppTypography.bodyMedium),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
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
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => GlassBottomSheet(
      child: SafeArea(
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
                leading: const Icon(LucideIcons.refreshCw,
                    color: AppColors.secondary),
                title: Text('Replace', style: AppTypography.bodyMedium),
                onTap: () => Navigator.of(sheetContext).pop('replace'),
              ),
              // Deliberately no "Remove" option here — the backend has no
              // document-delete endpoint for any of profile/KYC/vehicle
              // documents (only upload/replace), so a Remove action could
              // only ever clear local state, making the document reappear
              // on the next refetch while implying it was actually
              // deleted. "Replace" is the real, backend-supported action
              // for changing a submitted document.
            ],
          ),
        ),
      ),
    ),
  );

  if (action == 'replace' && context.mounted) {
    await pickAndUploadDocument(context, ref, document.type);
  }
}

Future<bool?> showSelfieConfirmSheet(BuildContext context, String path) async {
  final navigator = Navigator.of(context);
  final localizations = MaterialLocalizations.of(context);
  final route = ModalBottomSheetRoute<bool>(
    backgroundColor: Colors.transparent,
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    isScrollControlled: false,
    barrierLabel: localizations.scrimLabel,
    barrierOnTapHint:
        localizations.scrimOnTapHint(localizations.bottomSheetLabel),
    modalBarrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
    builder: (sheetContext) => GlassBottomSheet(
      child: SafeArea(
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
    ),
  );

  final result = await navigator.push<bool>(route);
  // Navigator.push completes as soon as pop is requested, while the modal
  // route remains on top until its reverse animation finishes. Waiting for
  // disposal prevents the caller from popping the page underneath while the
  // navigator is still finalising this bottom-sheet route.
  await route.completed;
  return result;
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
    String? path;
    if (cameraOnly) {
      final cameraConfig = ref.read(cameraConfigProvider);
      final navigator = Navigator.of(context);
      final cameraRoute = MaterialPageRoute<String>(
        builder: (_) => SelfieCameraCaptureScreen(
          cameraListLoader: cameraConfig.cameraListLoader,
          controllerBuilder: cameraConfig.controllerBuilder,
        ),
      );
      path = await navigator.push<String>(cameraRoute);
      // A route's pop result is delivered before its transition and disposal
      // complete. Do not place a bool-returning confirmation route above a
      // String-returning camera route that is still being removed.
      await cameraRoute.completed;
    } else {
      final source = await showImageSourceSheet(context);
      if (source == null) return false;
      path = await ref.read(documentImagePickerProvider).pickImage(source);
    }
    if (path == null || !context.mounted) return false;
    final useThisPhoto = await showSelfieConfirmSheet(context, path);
    if (useThisPhoto == null) return false;
    if (useThisPhoto == false) continue;

    try {
      await ref.read(profileRepositoryProvider).uploadSelfie(File(path));
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) rethrow;
      if (context.mounted) {
        AppSnackBar.error(context, error.message);
      }
      return false;
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Upload failed, please try again');
      }
      return false;
    }
  }
}
