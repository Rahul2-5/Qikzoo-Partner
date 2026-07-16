import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/document_verification/document_model.dart';
import '../../../providers/document_verification/documents_provider.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../partner_registration/widgets/document_upload_actions.dart';
import '../../partner_registration/widgets/document_upload_tile.dart';
import '../../profile/widgets/account_screen_components.dart';

const managedDocumentTypes = [
  DocumentType.aadhaar,
  DocumentType.pan,
  DocumentType.drivingLicense,
  DocumentType.vehicleRc,
  DocumentType.vehicleInsurance,
  DocumentType.vehiclePhoto,
  DocumentType.bankProof,
];

class ManageDocumentsScreen extends ConsumerWidget {
  const ManageDocumentsScreen({super.key});

  bool _isAvailable(DocumentModel document) =>
      document.status == DocumentStatus.pendingVerification ||
      document.status == DocumentStatus.verified;

  Future<void> _handleDocument(
    BuildContext context,
    WidgetRef ref,
    DocumentModel document,
  ) async {
    if (_isAvailable(document) && document.fileUrl != null) {
      await showDocumentPreviewSheet(context, ref, document);
    } else {
      await pickAndUploadDocument(context, ref, document.type);
    }
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
              const AccountScreenHeader(
                title: 'Documents',
                subtitle:
                    'View verification status and keep your documents current.',
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
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 40,
                          color: AppColors.warning,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Could not load your documents',
                          style: AppTypography.body,
                        ),
                        TextButton(
                          onPressed: () => ref.invalidate(documentsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (documents) {
                    final byType = {
                      for (final document in documents) document.type: document,
                    };
                    final managedDocuments = [
                      for (final type in managedDocumentTypes)
                        byType[type] ??
                            DocumentModel(
                              type: type,
                              status: DocumentStatus.notUploaded,
                            ),
                    ];
                    final submitted =
                        managedDocuments.where(_isAvailable).length;
                    final verified = managedDocuments
                        .where((document) =>
                            document.status == DocumentStatus.verified)
                        .length;

                    return RefreshIndicator(
                      onRefresh: () => ref.refresh(documentsProvider.future),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          _DocumentSummaryCard(
                            submitted: submitted,
                            verified: verified,
                            total: managedDocuments.length,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const AccountInfoBanner(
                            icon: LucideIcons.camera,
                            title: 'Upload clear, readable photos',
                            message:
                                'Make sure all four corners are visible and details are not blurred.',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Identity documents',
                              style: AppTypography.bodyMedium),
                          const SizedBox(height: AppSpacing.sm),
                          for (final type in const [
                            DocumentType.aadhaar,
                            DocumentType.pan,
                            DocumentType.drivingLicense,
                          ]) ...[
                            DocumentUploadTile(
                              document: byType[type] ??
                                  DocumentModel(
                                    type: type,
                                    status: DocumentStatus.notUploaded,
                                  ),
                              onTap: () => _handleDocument(
                                context,
                                ref,
                                byType[type] ??
                                    DocumentModel(
                                      type: type,
                                      status: DocumentStatus.notUploaded,
                                    ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Text('Vehicle documents',
                              style: AppTypography.bodyMedium),
                          const SizedBox(height: AppSpacing.sm),
                          for (final type in const [
                            DocumentType.vehicleRc,
                            DocumentType.vehicleInsurance,
                            DocumentType.vehiclePhoto,
                          ]) ...[
                            DocumentUploadTile(
                              document: byType[type] ??
                                  DocumentModel(
                                    type: type,
                                    status: DocumentStatus.notUploaded,
                                  ),
                              onTap: () => _handleDocument(
                                context,
                                ref,
                                byType[type] ??
                                    DocumentModel(
                                      type: type,
                                      status: DocumentStatus.notUploaded,
                                    ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Text('Payment document',
                              style: AppTypography.bodyMedium),
                          const SizedBox(height: AppSpacing.sm),
                          DocumentUploadTile(
                            document: byType[DocumentType.bankProof] ??
                                const DocumentModel(
                                  type: DocumentType.bankProof,
                                  status: DocumentStatus.notUploaded,
                                ),
                            onTap: () => _handleDocument(
                              context,
                              ref,
                              byType[DocumentType.bankProof] ??
                                  const DocumentModel(
                                    type: DocumentType.bankProof,
                                    status: DocumentStatus.notUploaded,
                                  ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentSummaryCard extends StatelessWidget {
  final int submitted;
  final int verified;
  final int total;

  const _DocumentSummaryCard({
    required this.submitted,
    required this.verified,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : submitted / total;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: const Icon(
                  LucideIcons.fileCheck2,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$submitted of $total submitted',
                      style: AppTypography.bodyMedium
                          .copyWith(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$verified verified',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
