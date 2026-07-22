import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/helpers/date_helper.dart';
import '../../../core/navigation/next_onboarding_step_resolver.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/onboarding_status/onboarding_status_model.dart';
import '../../../repositories/onboarding_status/onboarding_status_repository.dart';
import '../../../repositories/profile/profile_repository.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';

/// Terminal/non-editable onboarding states — SUBMITTED, UNDER_REVIEW,
/// APPROVED-but-not-yet-ACTIVE, and REJECTED. Reached only via
/// [NextOnboardingStepResolver], which already routes here for exactly
/// these states (see its `!status.isEditable` branch) — never hardcoded.
class VerificationStatusScreen extends ConsumerStatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  ConsumerState<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState
    extends ConsumerState<VerificationStatusScreen> {
  bool _isLoading = true;
  String? _loadError;
  OnboardingStatusModel? _status;
  bool _isReapplying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final status =
          await ref.read(onboardingStatusRepositoryProvider).getStatus();
      if (!mounted) return;
      // The rider's state may have moved on since they last opened this
      // screen (admin reopened a section for clarification, account went
      // active, reapply just succeeded) — resolve and leave automatically
      // rather than leaving them stuck on a stale status screen.
      if (status.isActive || status.isEditable) {
        final profile = await ref.read(profileRepositoryProvider).getProfile();
        if (!mounted) return;
        Get.offAllNamed(
            NextOnboardingStepResolver.resolve(status, profile: profile));
        return;
      }
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e is ApiException
            ? e.message
            : 'Could not load your verification status.';
      });
    }
  }

  Future<void> _onReapply() async {
    if (_isReapplying) return;
    setState(() => _isReapplying = true);
    try {
      await ref.read(onboardingStatusRepositoryProvider).reapply();
      if (!mounted) return;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isReapplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load your status', style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final status = _status!;
    final content = _contentFor(status);

    return RefreshIndicator(
      color: AppColors.secondary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: content.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(content.icon, color: content.color, size: 40),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: AppTypography.h1.copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              content.message,
              textAlign: TextAlign.center,
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          if (status.onboardingStatus == RiderOnboardingStatus.rejected &&
              status.rejectionReason != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.error, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(status.rejectionReason!,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
          if (status.submittedAt != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                'Submitted on ${DateHelper.formatShort(status.submittedAt!)}',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
          if (status.onboardingStatus == RiderOnboardingStatus.rejected &&
              status.reapplyAllowed) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: PrimaryCtaButton(
                label: 'Reapply',
                isLoading: _isReapplying,
                onPressed: _isReapplying ? null : _onReapply,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusContent _contentFor(OnboardingStatusModel status) {
    return switch (status.onboardingStatus) {
      RiderOnboardingStatus.notStarted ||
      RiderOnboardingStatus.inProgress =>
        const _StatusContent(
          icon: LucideIcons.clock,
          color: AppColors.warning,
          title: 'Onboarding in progress',
          message: 'Finish the remaining sections to submit your application.',
        ),
      RiderOnboardingStatus.clarificationRequired => const _StatusContent(
          icon: LucideIcons.alertTriangle,
          color: AppColors.warning,
          title: 'Action needed',
          message: 'Some details need a fix before we can continue review.',
        ),
      RiderOnboardingStatus.submitted ||
      RiderOnboardingStatus.underReview =>
        const _StatusContent(
          icon: LucideIcons.hourglass,
          color: AppColors.secondary,
          title: 'Application under review',
          message:
              "We're verifying your details. This usually takes 24-48 hours.",
        ),
      RiderOnboardingStatus.approved => const _StatusContent(
          icon: LucideIcons.checkCircle2,
          color: AppColors.success,
          title: 'Application approved',
          message: "You're approved! We're finishing setting up your account.",
        ),
      RiderOnboardingStatus.rejected => const _StatusContent(
          icon: LucideIcons.xCircle,
          color: AppColors.error,
          title: 'Application rejected',
          message: 'Your application was not approved this time.',
        ),
      RiderOnboardingStatus.unknown => const _StatusContent(
          icon: LucideIcons.clock,
          color: AppColors.textSecondary,
          title: 'Checking your status',
          message: 'Pull down to refresh.',
        ),
    };
  }
}

class _StatusContent {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _StatusContent({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}
