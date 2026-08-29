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
import '../../../providers/profile/profile_provider.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/step_progress_indicator.dart';
import '../widgets/document_upload_actions.dart';
import '../widgets/selfie_preview_frame.dart';

const _qikzooNavy = Color(0xFF162B4D);

class SelfieVerificationScreen extends ConsumerStatefulWidget {
  /// True when a rider must verify their face immediately before a shift.
  final bool isOnlineCheck;

  const SelfieVerificationScreen({
    super.key,
    this.isOnlineCheck = false,
  });

  @override
  ConsumerState<SelfieVerificationScreen> createState() =>
      _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState
    extends ConsumerState<SelfieVerificationScreen> {
  bool _isProcessing = false;

  Future<void> _captureOnlineSelfie() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final uploaded = await pickAndConfirmSelfie(
        context,
        ref,
        cameraOnly: true,
      );
      if (!mounted) return;
      if (uploaded) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _captureOnboardingSelfie() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final uploaded = await pickAndConfirmSelfie(context, ref);
      if (uploaded && mounted) {
        ref.invalidate(profileProvider);
        await ref.read(profileProvider.future);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _close() {
    if (_isProcessing) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final selfieUrl = ref.watch(profileProvider).valueOrNull?.selfieUrl;
    final profilePhoto = selfieUrl != null
        ? DocumentModel(
            type: DocumentType.profilePhoto,
            status: DocumentStatus.pendingVerification,
            fileUrl: selfieUrl,
          )
        : null;
    final isUploaded = profilePhoto != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 480,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 700;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: compact ? AppSpacing.sm : AppSpacing.md,
                ),
                // No scroll view: the card is Expanded and lays out its own
                // content against whatever height remains, so this always
                // fits a single screen.
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _SelfieTopBar(
                      isOnlineCheck: widget.isOnlineCheck,
                      onBack: _isProcessing ? null : _close,
                    ),
                    if (!widget.isOnlineCheck) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const StepProgressIndicator(
                        totalSteps: 6,
                        currentStep: 5,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: _SelfieCard(
                        profilePhoto: profilePhoto,
                        isUploaded: isUploaded,
                        isOnlineCheck: widget.isOnlineCheck,
                        compact: compact,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryCtaButton(
                      label: isUploaded ? 'Continue' : 'Take selfie now',
                      trailingIcon: isUploaded
                          ? LucideIcons.arrowRight
                          : LucideIcons.camera,
                      isLoading: _isProcessing,
                      onPressed: _isProcessing
                          ? null
                          : (widget.isOnlineCheck
                              ? _captureOnlineSelfie
                              : (isUploaded
                                  ? () => Get.toNamed(AppRoutes.welcomeKit)
                                  : _captureOnboardingSelfie)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _TrustRow(
                      text: widget.isOnlineCheck
                          ? 'Required before you can go online'
                          : (isUploaded
                              ? "You're all set for the next step"
                              : 'Takes less than a minute'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Plain back button + optional right-side badge — the same top-bar
/// anatomy as [PartnerBenefitsScreen]'s `_buildTopBar` (back, spacer,
/// badge). No brand mark here: the logo already appears once, at flow
/// entry, and repeating it on every inner step is just noise.
class _SelfieTopBar extends StatelessWidget {
  const _SelfieTopBar({
    required this.isOnlineCheck,
    required this.onBack,
  });

  final bool isOnlineCheck;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButtonCustom(
            icon: LucideIcons.arrowLeft,
            tooltip: 'Back',
            onPressed: onBack,
          ),
          const Spacer(),
          if (isOnlineCheck) const _SecureBadge(),
        ],
      );
}

/// The verification card: eyebrow label, headline, photo, status pill, and
/// a secure/encrypted note — the same card anatomy as the rest of the auth
/// flow (eyebrow pill → navy headline → supporting copy → content).
class _SelfieCard extends StatelessWidget {
  const _SelfieCard({
    required this.profilePhoto,
    required this.isUploaded,
    required this.isOnlineCheck,
    required this.compact,
  });

  final DocumentModel? profilePhoto;
  final bool isUploaded;
  final bool isOnlineCheck;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, inner) {
            final h = inner.maxHeight;
            final heroSize = (h * 0.46).clamp(140.0, 232.0).toDouble();
            final gapSm = (h * 0.02).clamp(6.0, 14.0);
            final gapMd = (h * 0.035).clamp(10.0, 22.0);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOnlineCheck ? 'IDENTITY CHECK' : 'IDENTITY VERIFICATION',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                SizedBox(height: gapSm),
                Text(
                  isUploaded ? 'Selfie ready' : "Let's confirm it's you",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTypography.display.copyWith(
                    color: _qikzooNavy,
                    fontSize: compact ? 20 : 25,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isUploaded
                      ? 'Review your photo, then continue.'
                      : 'Center your face in good light.',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
                SizedBox(height: gapMd),
                if (isUploaded)
                  SelfiePreviewFrame(
                    profilePhoto: profilePhoto,
                    size: heroSize,
                  )
                else
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: _SelfieDoDontGrid(),
                    ),
                  ),
                SizedBox(height: gapSm),
                _StatusPill(isUploaded: isUploaded),
                SizedBox(height: gapMd),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.shieldCheck,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Secure & encrypted',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _SelfieDoDontGrid extends StatelessWidget {
  const _SelfieDoDontGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      _GridItem(icon: LucideIcons.smile, label: 'Correct', isCorrect: true),
      _GridItem(icon: LucideIcons.eyeOff, label: 'Blurry', isCorrect: false),
      _GridItem(icon: LucideIcons.hardHat, label: 'Helmet', isCorrect: false),
      _GridItem(icon: LucideIcons.smile, label: 'Face Mask', isCorrect: false, hasMaskOverlay: true),
      _GridItem(icon: LucideIcons.glasses, label: 'Glasses', isCorrect: false),
      _GridItem(icon: LucideIcons.moon, label: 'Dark Light', isCorrect: false),
      _GridItem(icon: LucideIcons.cornerUpRight, label: 'Side Angle', isCorrect: false),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, idx) => items[idx],
    );
  }
}

class _GridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCorrect;
  final bool hasMaskOverlay;

  const _GridItem({
    required this.icon,
    required this.label,
    required this.isCorrect,
    this.hasMaskOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = isCorrect ? AppColors.success : AppColors.error;
    final badgeIcon = isCorrect ? LucideIcons.check : LucideIcons.x;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect ? AppColors.success.withValues(alpha: 0.6) : AppColors.border,
          width: isCorrect ? 1.5 : 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isCorrect ? AppColors.success : AppColors.textSecondary,
                    ),
                    if (hasMaskOverlay)
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(badgeIcon, color: badgeColor, size: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isUploaded});

  final bool isUploaded;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isUploaded ? AppColors.successBg : AppColors.secondarySoft,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUploaded ? LucideIcons.checkCircle2 : LucideIcons.scanFace,
              size: 15,
              color: isUploaded ? AppColors.success : AppColors.secondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isUploaded ? 'Photo uploaded' : 'Face the camera directly',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: isUploaded ? AppColors.success : AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

/// The small checkmark + caption trust line under the CTA, matching the
/// "Takes only a few minutes" / "Set up your profile" pattern used on the
/// welcome and benefits screens.
class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.checkCircle2,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
}

class _SecureBadge extends StatelessWidget {
  const _SecureBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.shieldCheck,
                size: 14, color: AppColors.success),
            const SizedBox(width: 5),
            Text(
              'Secure',
              style: AppTypography.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}