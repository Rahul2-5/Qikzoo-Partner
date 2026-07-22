import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/navigation/next_onboarding_step_resolver.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/validators/validators.dart';
import '../../../models/profile/partner_profile_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../repositories/onboarding_status/onboarding_status_repository.dart';
import '../../../repositories/profile/profile_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/labeled_field.dart';
import '../widgets/onboarding_progress_bar.dart';

/// Rider onboarding Emergency Contact step. Backend has no dedicated
/// endpoint — `emergencyContactName`/`emergencyContactPhone` are just two
/// more optional fields on `PATCH /rider/profile`, same as Personal
/// Details/Address before it.
class EmergencyContactScreen extends ConsumerStatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  ConsumerState<EmergencyContactScreen> createState() =>
      _EmergencyContactScreenState();
}

class _EmergencyContactScreenState
    extends ConsumerState<EmergencyContactScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  String? _loadError;
  PartnerProfileModel? _original;

  bool _nameTouched = false;
  bool _phoneTouched = false;
  bool _isSaving = false;
  bool _sectionLocked = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final profile = await ref.read(profileRepositoryProvider).getProfile();
      if (!mounted) return;
      setState(() {
        _original = profile;
        _nameController.text = profile.emergencyContactName ?? '';
        _phoneController.text = profile.emergencyContactPhone ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e is ApiException
            ? e.message
            : 'Could not load your emergency contact.';
      });
    }
  }

  bool get _isNameValid => _nameController.text.trim().isNotEmpty;

  bool get _isPhoneValid {
    final phone = _phoneController.text.trim();
    if (!Validators.isValidPhone(phone)) return false;
    final own = _original?.phone.trim() ?? '';
    return _normalizePhone(phone) != _normalizePhone(own);
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  bool get _isFormValid => _isNameValid && _isPhoneValid;

  bool get _isDirty {
    final o = _original;
    if (o == null) return false;
    return _nameController.text.trim() != (o.emergencyContactName ?? '') ||
        _phoneController.text.trim() != (o.emergencyContactPhone ?? '');
  }

  bool get _canSave =>
      !_isLoading &&
      _loadError == null &&
      !_sectionLocked &&
      !_isSaving &&
      _isFormValid &&
      _isDirty;

  Future<String> _resolveNextRoute(PartnerProfileModel profile) async {
    try {
      final status =
          await ref.read(onboardingStatusRepositoryProvider).getStatus();
      return NextOnboardingStepResolver.resolve(status, profile: profile);
    } catch (_) {
      return AppRoutes.review;
    }
  }

  Future<void> _onSave() async {
    if (!_canSave) return;
    setState(() {
      _isSaving = true;
      _isOffline = false;
    });
    try {
      final updatedProfile =
          await ref.read(profileRepositoryProvider).updateEmergencyContact(
                emergencyContactName: _nameController.text.trim(),
                emergencyContactPhone: _phoneController.text.trim(),
              );
      if (!mounted) return;
      Get.toNamed(await _resolveNextRoute(updatedProfile));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await ref.read(authSessionProvider.notifier).logout();
        if (!mounted) return;
        Get.offAllNamed(AppRoutes.welcome);
        return;
      }
      setState(() {
        _isSaving = false;
        _sectionLocked = e.statusCode == 403;
        _isOffline = e.code == DioExceptionType.connectionError.name;
      });
      if (!_isOffline) {
        AppSnackBar.show(
          context,
          message: e.message,
          type: AppSnackBarType.error,
          actionLabel: e.statusCode == 403 ? null : 'Retry',
          onAction: e.statusCode == 403 ? null : _onSave,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
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
              const OnboardingProgressBar(currentStep: 4),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _buildBody(context)),
              if (!_isLoading && _loadError == null) ...[
                PrimaryCtaButton(
                  label: 'Save',
                  trailingIcon: LucideIcons.arrowRight,
                  isLoading: _isSaving,
                  onPressed: _canSave ? _onSave : null,
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
            Text('Could not load your emergency contact',
                style: AppTypography.body),
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
                    text: 'Emergency ',
                    style: TextStyle(color: AppColors.textPrimary)),
                TextSpan(
                  text: 'Contact',
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
            'Someone we can reach in case of an emergency',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
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
              onAction: _onSave,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledField(
                  label: 'Contact Name',
                  child: AppTextField(
                    label: 'Contact Name',
                    controller: _nameController,
                    showFloatingLabel: false,
                    hint: "Contact's full name",
                    readOnly: _sectionLocked,
                    textCapitalization: TextCapitalization.words,
                    errorText: _nameTouched && !_isNameValid
                        ? 'Contact name is required'
                        : null,
                    prefixIcon: const Icon(LucideIcons.user,
                        color: AppColors.secondary, size: 20),
                    onChanged: (_) => setState(() => _nameTouched = true),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Relationship',
                  child: Text(
                    'e.g. Parent, Spouse, Sibling — not stored separately, '
                    'just note it alongside the name above if useful.',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Contact Phone Number',
                  child: AppTextField(
                    label: 'Contact Phone Number',
                    controller: _phoneController,
                    showFloatingLabel: false,
                    hint: '10-digit mobile number',
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    readOnly: _sectionLocked,
                    errorText: _phoneTouched && !_isPhoneValid
                        ? (Validators.isValidPhone(
                                _phoneController.text.trim())
                            ? 'Cannot be the same as your own number'
                            : 'Enter a valid 10-digit phone number')
                        : null,
                    prefixIcon: const Icon(LucideIcons.phone,
                        color: AppColors.secondary, size: 20),
                    onChanged: (_) => setState(() => _phoneTouched = true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
