import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/submitted_illustration.dart';

class ApplicationSubmittedScreen extends StatelessWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              IconButtonCustom(icon: LucideIcons.arrowLeft, onPressed: () => Get.back()),
              const SizedBox(height: AppSpacing.lg),
              Text.rich(
                TextSpan(
                  style: AppTypography.h1.copyWith(fontSize: 26),
                  children: [
                    const TextSpan(
                      text: 'Application ',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: 'Submitted',
                      style: TextStyle(
                        foreground: Paint()
                          ..shader = const LinearGradient(colors: AppColors.ctaGradient)
                              .createShader(const Rect.fromLTWH(0, 0, 180, 26)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const Center(child: SubmittedIllustration()),
                      const SizedBox(height: AppSpacing.lg),
                      Text.rich(
                        TextSpan(
                          style: AppTypography.h2.copyWith(fontSize: 20),
                          children: [
                            const TextSpan(
                              text: 'Your application has been submitted ',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            TextSpan(
                              text: 'successfully!',
                              style: TextStyle(
                                foreground: Paint()
                                  ..shader = const LinearGradient(colors: AppColors.ctaGradient)
                                      .createShader(const Rect.fromLTWH(0, 0, 140, 20)),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'We will verify your details and get back to you soon.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "What's next?",
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.success),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const _NextStepRow(
                              icon: LucideIcons.search,
                              label: 'Document verification (1–2 days)',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const _NextStepRow(
                              icon: LucideIcons.user,
                              label: 'Background verification',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const _NextStepRow(
                              icon: LucideIcons.truck,
                              label: 'Activation and training',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              PrimaryCtaButton(
                label: 'Go to Home',
                trailingIcon: LucideIcons.arrowRight,
                onPressed: () => Get.offAllNamed(AppRoutes.dashboard),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '6',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Application Submitted',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextStepRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _NextStepRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.success, size: 16),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTypography.body)),
      ],
    );
  }
}
