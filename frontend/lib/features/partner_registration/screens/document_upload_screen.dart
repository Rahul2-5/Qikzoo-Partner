import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/document_verification/document_model.dart';
import '../../../providers/document_verification/documents_provider.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/step_progress_indicator.dart';
import '../widgets/document_upload_actions.dart';
import '../widgets/document_upload_tile.dart';

const documentDisplayOrder = [
  DocumentType.aadhaar,
  DocumentType.drivingLicense,
  DocumentType.vehicleRc,
  DocumentType.vehicleInsurance,
  DocumentType.pan,
];

const _requiredDocumentTypes = [
  DocumentType.aadhaar,
  DocumentType.drivingLicense,
  DocumentType.vehicleRc,
  DocumentType.vehicleInsurance,
];

bool _isUploaded(DocumentStatus status) =>
    status == DocumentStatus.pendingVerification ||
    status == DocumentStatus.verified;

List<String> missingRequiredDocumentLabels(List<DocumentModel> documents) {
  final byType = {for (final doc in documents) doc.type: doc};
  return [
    for (final type in _requiredDocumentTypes)
      if (!_isUploaded(byType[type]?.status ?? DocumentStatus.notUploaded))
        type.label,
  ];
}

class DocumentUploadScreen extends ConsumerWidget {
  const DocumentUploadScreen({super.key});

  void _onContinue(BuildContext context, List<DocumentModel> documents) {
    final missing = missingRequiredDocumentLabels(documents);
    if (missing.isNotEmpty) {
      AppSnackBar.warning(
        context,
        'Please upload: ${missing.join(', ')}',
      );
      return;
    }
    Get.toNamed(AppRoutes.selfieVerification);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              IconButtonCustom(
                  icon: LucideIcons.arrowLeft, onPressed: () => Get.back()),
              const SizedBox(height: AppSpacing.lg),
              const StepProgressIndicator(totalSteps: 6, currentStep: 4),
              const SizedBox(height: AppSpacing.lg),
              Text.rich(
                TextSpan(
                  style: AppTypography.h1.copyWith(fontSize: 26),
                  children: [
                    const TextSpan(
                      text: 'Upload ',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: 'Documents',
                      style: TextStyle(
                        foreground: Paint()
                          ..shader = const LinearGradient(
                                  colors: AppColors.ctaGradient)
                              .createShader(const Rect.fromLTWH(0, 0, 160, 26)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Upload clear photos of the following documents',
                style:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: documentsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load documents',
                            style: AppTypography.body),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: () => ref.invalidate(documentsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (documents) {
                    final byType = {for (final doc in documents) doc.type: doc};
                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: documentDisplayOrder.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final type = documentDisplayOrder[index];
                        final document = byType[type] ??
                            DocumentModel(
                                type: type, status: DocumentStatus.notUploaded);
                        final isUploaded = _isUploaded(document.status);
                        return DocumentUploadTile(
                          document: document,
                          onTap: () => isUploaded
                              ? showDocumentPreviewSheet(context, ref, document)
                              : pickAndUploadDocument(context, ref, type),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryCtaButton(
                label: 'Continue',
                trailingIcon: LucideIcons.arrowRight,
                onPressed: () =>
                    _onContinue(context, documentsAsync.valueOrNull ?? []),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
