import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/submitted_illustration.dart';

class ApplicationSubmittedScreen extends StatefulWidget {
  final Duration redirectDelay;

  const ApplicationSubmittedScreen({
    super.key,
    this.redirectDelay = const Duration(seconds: 5),
  });

  @override
  State<ApplicationSubmittedScreen> createState() =>
      _ApplicationSubmittedScreenState();
}

class _ApplicationSubmittedScreenState
    extends State<ApplicationSubmittedScreen> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(widget.redirectDelay, _goToHome);
  }

  void _goToHome() {
    if (!mounted) return;
    Get.offAllNamed(AppRoutes.dashboard, arguments: true);
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 520,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.checkCircle2,
                            color: AppColors.success,
                            size: 17,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Payment successful',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const SubmittedIllustration(),
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
                                ..shader = const LinearGradient(
                                  colors: AppColors.ctaGradient,
                                ).createShader(
                                  const Rect.fromLTWH(0, 0, 180, 26),
                                ),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Your application has been submitted successfully. We’ll verify your details and get back to you soon.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.success,
                            ),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  'Taking you to Home in 5 seconds…',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TweenAnimationBuilder<double>(
                            duration: widget.redirectDelay,
                            tween: Tween(begin: 0, end: 1),
                            builder: (context, value, child) {
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 5,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.chip),
                                backgroundColor: AppColors.surfaceMuted,
                                color: AppColors.secondary,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
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
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.success, size: 16),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTypography.body)),
      ],
    );
  }
}

@Preview(
  name: 'Application submitted',
  group: 'Partner registration',
  size: Size(390, 844),
)
Widget applicationSubmittedScreenPreview() {
  return GetMaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const ApplicationSubmittedScreen(
      redirectDelay: Duration(days: 1),
    ),
  );
}
