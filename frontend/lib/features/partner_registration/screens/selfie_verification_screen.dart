import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/document_verification/document_model.dart';
import '../../../providers/document_verification/documents_provider.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/step_progress_indicator.dart';
import '../widgets/document_upload_actions.dart';
import '../widgets/selfie_preview_frame.dart';

class SelfieVerificationScreen extends ConsumerWidget {
  /// True when a rider must verify their face immediately before a shift.
  final bool isOnlineCheck;

  const SelfieVerificationScreen({
    super.key,
    this.isOnlineCheck = false,
  });

  Future<void> _captureOnlineSelfie(BuildContext context, WidgetRef ref) async {
    final uploaded = await pickAndConfirmSelfie(
      context,
      ref,
      cameraOnly: true,
    );
    if (uploaded && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);
    final documents = documentsAsync.valueOrNull ?? const <DocumentModel>[];

    DocumentModel? profilePhoto;
    for (final doc in documents) {
      if (doc.type == DocumentType.profilePhoto) {
        profilePhoto = doc;
        break;
      }
    }

    final isUploaded = profilePhoto != null &&
        (profilePhoto.status == DocumentStatus.pendingVerification ||
            profilePhoto.status == DocumentStatus.verified);

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
              if (!isOnlineCheck)
                const StepProgressIndicator(totalSteps: 6, currentStep: 5),
              const SizedBox(height: AppSpacing.lg),
              Text.rich(
                TextSpan(
                  style: AppTypography.h1.copyWith(fontSize: 26),
                  children: [
                    TextSpan(
                      text: isOnlineCheck ? 'Quick ' : 'Take a ',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: isOnlineCheck ? 'selfie check' : 'Selfie',
                      style: TextStyle(
                        foreground: Paint()
                          ..shader = const LinearGradient(
                                  colors: AppColors.ctaGradient)
                              .createShader(const Rect.fromLTWH(0, 0, 100, 26)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isOnlineCheck
                    ? 'Take a clear selfie to start receiving delivery requests.'
                    : 'Take a clear selfie for verification',
                style:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child:
                              SelfiePreviewFrame(profilePhoto: profilePhoto)),
                      const SizedBox(height: AppSpacing.lg),
                      const _SelfieTipRow(
                        icon: LucideIcons.user,
                        label: 'Make sure your face is clearly visible',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const _SelfieTipRow(
                          icon: LucideIcons.sun, label: 'Good lighting'),
                      const SizedBox(height: AppSpacing.sm),
                      const _SelfieTipRow(
                        icon: LucideIcons.glasses,
                        label: 'No sunglasses or filters',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              PrimaryCtaButton(
                label: isOnlineCheck
                    ? 'Take selfie'
                    : (isUploaded ? 'Continue' : 'Capture'),
                trailingIcon:
                    isOnlineCheck || !isUploaded
                        ? LucideIcons.camera
                        : LucideIcons.arrowRight,
                onPressed: isOnlineCheck
                    ? () => _captureOnlineSelfie(context, ref)
                    : (isUploaded
                        ? () => Get.toNamed(AppRoutes.welcomeKit)
                        : () => pickAndConfirmSelfie(context, ref)),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelfieTipRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SelfieTipRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTypography.body)),
      ],
    );
  }
}
