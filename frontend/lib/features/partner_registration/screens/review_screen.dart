import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/helpers/date_helper.dart';
import '../../../core/navigation/next_onboarding_step_resolver.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/kyc/rider_kyc_model.dart';
import '../../../models/onboarding_status/onboarding_status_model.dart';
import '../../../models/profile/partner_profile_model.dart';
import '../../../models/vehicle/rider_vehicle_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../repositories/kyc/kyc_repository.dart';
import '../../../repositories/onboarding_status/onboarding_status_repository.dart';
import '../../../repositories/profile/profile_repository.dart';
import '../../../repositories/vehicle/vehicle_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/onboarding_progress_bar.dart';

/// Rider onboarding Review & Submit step — the last screen before
/// `POST /rider/onboarding/submit`. Reloads every section's latest data
/// fresh from the backend each time it's shown (including on return from
/// an Edit), rather than caching/duplicating state already owned by each
/// section's own screen.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  /// A fixed version pair for the terms/privacy-policy the rider is
  /// agreeing to on submit — the backend requires *some* version string
  /// (`SubmitOnboardingDto.termsVersion`/`privacyPolicyVersion`) but does
  /// not expose an endpoint describing "the current version"; this is an
  /// app-release-level constant, bumped whenever the terms shown to riders
  /// change.
  static const _termsVersion = '2026-01-01';
  static const _privacyPolicyVersion = '2026-01-01';

  bool _isLoading = true;
  String? _loadError;
  PartnerProfileModel? _profile;
  RiderKycModel? _kyc;
  List<RiderVehicleModel> _vehicles = [];
  OnboardingStatusModel? _status;

  bool _acceptedTerms = false;
  bool _isSubmitting = false;
  bool _sectionLocked = false;
  bool _isOffline = false;

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
      final results = await Future.wait([
        ref.read(profileRepositoryProvider).getProfile(),
        ref.read(kycRepositoryProvider).getKyc(),
        ref.read(vehicleRepositoryProvider).listVehicles(),
        ref.read(onboardingStatusRepositoryProvider).getStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as PartnerProfileModel;
        _kyc = results[1] as RiderKycModel?;
        _vehicles = results[2] as List<RiderVehicleModel>;
        _status = results[3] as OnboardingStatusModel;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError =
            e is ApiException ? e.message : 'Could not load your details.';
      });
    }
  }

  Future<void> _editSection(String route) async {
    await Get.toNamed(route);
    if (mounted) _load();
  }

  bool get _canSubmit =>
      !_isLoading &&
      _loadError == null &&
      !_sectionLocked &&
      !_isSubmitting &&
      _acceptedTerms &&
      (_status?.isSubmittable ?? false);

  Future<void> _onSubmit() async {
    if (!_canSubmit) return;
    setState(() {
      _isSubmitting = true;
      _isOffline = false;
    });
    try {
      await ref.read(onboardingStatusRepositoryProvider).submitOnboarding(
            termsVersion: _termsVersion,
            privacyPolicyVersion: _privacyPolicyVersion,
          );
      if (!mounted) return;
      final status =
          await ref.read(onboardingStatusRepositoryProvider).getStatus();
      final profile =
          _profile ?? await ref.read(profileRepositoryProvider).getProfile();
      if (!mounted) return;
      Get.offAllNamed(
          NextOnboardingStepResolver.resolve(status, profile: profile));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await ref.read(authSessionProvider.notifier).logout();
        if (!mounted) return;
        Get.offAllNamed(AppRoutes.welcome);
        return;
      }
      setState(() {
        _isSubmitting = false;
        _sectionLocked = e.statusCode == 403;
        _isOffline = e.code == DioExceptionType.connectionError.name;
      });
      if (!_isOffline) {
        AppSnackBar.show(
          context,
          message: e.message,
          type: AppSnackBarType.error,
          actionLabel: e.statusCode == 403 ? null : 'Retry',
          onAction: e.statusCode == 403 ? null : _onSubmit,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackBar.error(context, 'Something went wrong. Please try again.');
    }
  }

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
              IconButtonCustom(
                  icon: LucideIcons.arrowLeft, onPressed: () => Get.back()),
              const SizedBox(height: AppSpacing.lg),
              const OnboardingProgressBar(currentStep: 5),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _buildBody(context)),
              if (!_isLoading && _loadError == null) ...[
                PrimaryCtaButton(
                  label: 'Submit for Review',
                  trailingIcon: LucideIcons.arrowRight,
                  isLoading: _isSubmitting,
                  onPressed: _canSubmit ? _onSubmit : null,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
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
            Text('Could not load your details', style: AppTypography.body),
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

    final profile = _profile!;
    final vehicle = _vehicles.firstWhere(
      (v) => v.isComplete,
      orElse: () => _vehicles.isNotEmpty
          ? _vehicles.first
          : const RiderVehicleModel(
              id: '',
              type: VehicleType.bike,
              registrationNumber: '',
              isActive: false,
            ),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: AppTypography.h1.copyWith(fontSize: 26),
              children: [
                const TextSpan(
                    text: 'Review & ',
                    style: TextStyle(color: AppColors.textPrimary)),
                TextSpan(
                  text: 'Submit',
                  style: TextStyle(
                    foreground: Paint()
                      ..shader = const LinearGradient(colors: AppColors.ctaGradient)
                          .createShader(const Rect.fromLTWH(0, 0, 140, 26)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Check everything before sending it for approval',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_sectionLocked) ...[
            const _InfoBanner(
              icon: LucideIcons.lock,
              color: AppColors.warning,
              message:
                  'This section is locked and can no longer be edited — it has already been submitted for review.',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_isOffline) ...[
            _InfoBanner(
              icon: LucideIcons.wifiOff,
              color: AppColors.error,
              message: "You're offline. Check your connection and try again.",
              actionLabel: 'Retry',
              onAction: _onSubmit,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_status?.hasExpiredMandatoryDocuments ?? false) ...[
            _InfoBanner(
              icon: LucideIcons.alertTriangle,
              color: AppColors.error,
              message:
                  'Your vehicle insurance has expired. Please renew and re-upload it before submitting.',
              actionLabel: 'Fix',
              onAction: () => _editSection(AppRoutes.vehicleRegistration),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _ReviewSectionCard(
            title: 'Personal Details',
            onEdit: () => _editSection(AppRoutes.personalInfo),
            rows: [
              _Row('Name', profile.name),
              if (profile.dateOfBirth != null)
                _Row('Date of Birth', DateHelper.formatShort(profile.dateOfBirth!)),
              if (profile.gender != null) _Row('Gender', profile.gender!.name),
              _Row('Photo', profile.photoUrl != null ? 'Uploaded' : 'Missing'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewSectionCard(
            title: 'Address',
            onEdit: () => _editSection(AppRoutes.address),
            rows: [
              _Row('Address Line 1', profile.addressLine1 ?? '—'),
              _Row('City', profile.city ?? '—'),
              _Row('State', profile.state ?? '—'),
              _Row('PIN Code', profile.pincode ?? '—'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewSectionCard(
            title: 'KYC',
            onEdit: () => _editSection(AppRoutes.kyc),
            rows: [
              _Row('Government ID', _kyc?.governmentIdType?.label ?? '—'),
              _Row('ID Document',
                  (_kyc?.hasGovernmentIdDocument ?? false) ? 'Uploaded' : 'Missing'),
              _Row('Driving Licence', _kyc?.drivingLicenseNumber ?? '—'),
              _Row('Licence Document',
                  (_kyc?.hasDrivingLicenseDocument ?? false) ? 'Uploaded' : 'Missing'),
              _Row('Bank Account', _kyc?.bankAccountNumberMasked ?? '—'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewSectionCard(
            title: 'Vehicle',
            onEdit: () => _editSection(AppRoutes.vehicleRegistration),
            rows: [
              _Row('Type', vehicle.registrationNumber.isEmpty ? '—' : vehicle.type.label),
              _Row('Registration Number',
                  vehicle.registrationNumber.isEmpty ? '—' : vehicle.registrationNumber),
              _Row('RC Document', vehicle.hasRcDocument ? 'Uploaded' : 'Missing'),
              _Row('Insurance Document',
                  vehicle.hasInsuranceDocument ? 'Uploaded' : 'Missing'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewSectionCard(
            title: 'Emergency Contact',
            onEdit: () => _editSection(AppRoutes.emergencyContact),
            rows: [
              _Row('Name', profile.emergencyContactName ?? '—'),
              _Row('Phone', profile.emergencyContactPhone ?? '—'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          InkWell(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    activeColor: AppColors.secondary,
                    onChanged: (value) =>
                        setState(() => _acceptedTerms = value ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'I confirm the information and documents provided are '
                        "accurate, and I agree to Qikzoo's Rider Partner Terms "
                        'and Privacy Policy.',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;
  const _Row(this.label, this.value);
}

class _ReviewSectionCard extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;
  final List<_Row> rows;

  const _ReviewSectionCard({
    required this.title,
    required this.onEdit,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800)),
              ),
              TextButton(onPressed: onEdit, child: const Text('Edit')),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(row.label,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: AppTypography.caption.copyWith(color: color)),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!,
                  style: AppTypography.caption
                      .copyWith(color: color, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}
