import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../repositories/document_verification/document_image_picker.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/online_selfie_image.dart';

/// Collects the shift selfie required before a partner can become available.
///
/// Returns the selected image path when verification succeeds, or `null` when
/// the partner leaves the flow.
class OnlineSelfieVerificationScreen extends ConsumerStatefulWidget {
  const OnlineSelfieVerificationScreen({super.key});

  @override
  ConsumerState<OnlineSelfieVerificationScreen> createState() =>
      _OnlineSelfieVerificationScreenState();
}

class _OnlineSelfieVerificationScreenState
    extends ConsumerState<OnlineSelfieVerificationScreen> {
  String? _selfiePath;
  bool _isPicking = false;
  bool _isSubmitting = false;

  bool get _canGoOnline => _selfiePath != null && !_isSubmitting;

  Future<void> _pickSelfie() async {
    setState(() => _isPicking = true);
    try {
      final path = await ref
          .read(documentImagePickerProvider)
          .pickImage(ImageSource.camera);
      if (!mounted || path == null) return;
      setState(() => _selfiePath = path);
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          'Could not open the camera. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _submit() async {
    if (!_canGoOnline) return;
    setState(() => _isSubmitting = true);

    // Keep the submit state explicit so a real upload API can replace this
    // hand-off without changing the screen or dashboard contract.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    Navigator.of(context).pop(_selfiePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButtonCustom(
                    icon: LucideIcons.arrowLeft,
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBg,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.shieldCheck,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Shift check',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('One quick check before\nyou go online',
                  style: AppTypography.h1.copyWith(fontSize: 28)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Take a fresh selfie wearing a plain white T-shirt. '
                'This keeps customers confident about who is delivering.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _SelfieCaptureCard(
                        selfiePath: _selfiePath,
                        isPicking: _isPicking,
                        onTap: _isPicking ? null : _pickSelfie,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Row(
                        children: [
                          Expanded(
                            child: _PhotoTip(
                              icon: LucideIcons.shirt,
                              label: 'White T-shirt',
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _PhotoTip(
                              icon: LucideIcons.sun,
                              label: 'Good lighting',
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _PhotoTip(
                              icon: LucideIcons.user,
                              label: 'Face visible',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              PrimaryCtaButton(
                label: 'Use Selfie & Go Online',
                trailingIcon: LucideIcons.arrowRight,
                isLoading: _isSubmitting,
                onPressed: _canGoOnline ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelfieCaptureCard extends StatelessWidget {
  const _SelfieCaptureCard({
    required this.selfiePath,
    required this.isPicking,
    required this.onTap,
  });

  final String? selfiePath;
  final bool isPicking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = selfiePath != null;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.sheet),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 270,
          decoration: BoxDecoration(
            border: Border.all(
              color: hasPhoto ? AppColors.secondary : AppColors.border,
              width: hasPhoto ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sheet),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sheet - 2),
                  child: OnlineSelfieImage(path: selfiePath!),
                )
              else
                const _EmptySelfieState(),
              if (hasPhoto)
                Positioned(
                  left: AppSpacing.md,
                  top: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Selfie added',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (hasPhoto)
                Positioned(
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      'Retake',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (isPicking)
                const ColoredBox(
                  color: Color(0x88FFFFFF),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySelfieState extends StatelessWidget {
  const _EmptySelfieState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FFFC), Color(0xFFEAF8F3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F12A783),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.camera,
              size: 32,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Tap to open camera', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Camera only • fresh photo required',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _PhotoTip extends StatelessWidget {
  const _PhotoTip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.secondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(
  name: 'Online selfie verification',
  group: 'Dashboard',
  size: Size(390, 844),
)
Widget onlineSelfieVerificationPreview() {
  return ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const OnlineSelfieVerificationScreen(),
    ),
  );
}
