import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/navigation/next_onboarding_step_resolver.dart';
import '../../../core/navigation/onboarding_back_navigation.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/validators/validators.dart';
import '../../../models/partner_registration/personal_info_model.dart';
import '../../../models/profile/partner_profile_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../repositories/document_verification/document_image_picker.dart';
import '../../../repositories/onboarding_status/onboarding_status_repository.dart';
import '../../../repositories/profile/profile_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/date_of_birth_field.dart';
import '../widgets/document_upload_actions.dart' show showImageSourceSheet;
import '../widgets/gender_selector.dart';
import '../widgets/labeled_field.dart';
import '../widgets/onboarding_progress_bar.dart';

enum _PhotoStatus { idle, uploading, error }

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  /// Mirrors the backend's `MAX_IMAGE_SIZE_BYTES` (image-validation.ts) so
  /// an oversized photo is rejected locally before spending an upload.
  static const _maxPhotoBytes = 5 * 1024 * 1024;
  static const _saveTimeout = Duration(seconds: 15);
  static const _statusLookupTimeout = Duration(seconds: 5);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = true;
  String? _loadError;
  PartnerProfileModel? _original;

  DateTime? _dateOfBirth;
  Gender? _gender;
  String? _photoUrl;
  String? _localPhotoPath;

  _PhotoStatus _photoStatus = _PhotoStatus.idle;
  double _photoProgress = 0;
  CancelToken? _photoCancelToken;

  bool _nameTouched = false;
  bool _emailTouched = false;
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
    _emailController.dispose();
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
        _nameController.text = profile.name;
        _emailController.text = profile.email ?? '';
        _dateOfBirth = profile.dateOfBirth;
        _gender = profile.gender;
        _photoUrl = profile.photoUrl;
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

  bool get _isNameValid => Validators.isValidFullName(_nameController.text);

  bool get _isEmailValid =>
      _emailController.text.trim().isEmpty ||
      Validators.isValidEmail(_emailController.text);

  bool get _isFormValid =>
      _isNameValid && _isEmailValid && _dateOfBirth != null && _gender != null;

  bool get _isDirty {
    final original = _original;
    if (original == null) return false;
    return _nameController.text.trim() != original.name ||
        _emailController.text.trim() != (original.email ?? '') ||
        _dateOfBirth != original.dateOfBirth ||
        _gender != original.gender;
  }

  bool get _canSave =>
      !_isLoading &&
      _loadError == null &&
      !_sectionLocked &&
      !_isSaving &&
      _isFormValid &&
      _isDirty;

  /// Asks the backend where the rider belongs next rather than hardcoding
  /// the following onboarding screen — see [NextOnboardingStepResolver].
  /// [profile] is the just-saved profile returned by [updatePersonalDetails]
  /// so this needs no extra fetch. If the status lookup is unavailable, the
  /// saved profile tells us whether Address is still needed, preventing an
  /// unrelated request from stranding the rider on the loading state.
  Future<String> _resolveNextRoute(PartnerProfileModel profile) async {
    try {
      final status = await ref
          .read(onboardingStatusRepositoryProvider)
          .getStatus()
          .timeout(_statusLookupTimeout);
      return NextOnboardingStepResolver.resolve(status, profile: profile);
    } catch (_) {
      // Personal details have already been saved. Continue through the
      // predictable next onboarding step rather than leaving the rider on a
      // loading button while an independent status request is unavailable.
      return profile.hasCompleteAddress
          ? AppRoutes.vehicleSelection
          : AppRoutes.address;
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
          await ref.read(profileRepositoryProvider).updatePersonalDetails(
                name: _nameController.text.trim(),
                email: _emailController.text.trim().isEmpty
                    ? null
                    : _emailController.text.trim(),
                dateOfBirth: _dateOfBirth!,
                gender: _gender!,
              ).timeout(_saveTimeout);
      if (!mounted) return;
      final nextRoute = await _resolveNextRoute(updatedProfile);
      if (!mounted) return;
      // Clear the busy state before pushing. If route configuration is ever
      // incomplete, the rider remains on an actionable form rather than a
      // permanently spinning Save button.
      setState(() => _isSaving = false);
      Get.toNamed(nextRoute);
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
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackBar.error(
        context,
        'Saving is taking too long. Check your connection and try again.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackBar.error(context, 'Something went wrong. Please try again.');
    }
  }

  Future<void> _goBack() => popOnboardingOrGoTo(context, AppRoutes.welcome);

  Future<void> _pickPhoto() async {
    if (_sectionLocked || _photoStatus == _PhotoStatus.uploading) return;
    final source = await showImageSourceSheet(context);
    if (source == null) return;
    final path = await ref.read(documentImagePickerProvider).pickImage(source);
    if (path == null) return;
    await _uploadPhoto(path);
  }

  Future<void> _uploadPhoto(String path) async {
    final file = File(path);
    final length = await file.length();
    if (length > _maxPhotoBytes) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        'Image exceeds the 5MB limit. Please choose a smaller photo.',
      );
      return;
    }

    setState(() {
      _localPhotoPath = path;
      _photoStatus = _PhotoStatus.uploading;
      _photoProgress = 0;
    });

    final cancelToken = CancelToken();
    _photoCancelToken = cancelToken;

    try {
      final updated =
          await ref.read(profileRepositoryProvider).uploadProfilePhoto(
        file,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          setState(() => _photoProgress = sent / total);
        },
      );
      if (!mounted) return;
      setState(() {
        _photoUrl = updated.photoUrl;
        _photoStatus = _PhotoStatus.idle;
        _localPhotoPath = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == DioExceptionType.cancel.name) {
        setState(() {
          _photoStatus = _PhotoStatus.idle;
          _localPhotoPath = null;
        });
        return;
      }
      setState(() => _photoStatus = _PhotoStatus.error);
      AppSnackBar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _photoStatus = _PhotoStatus.error);
      AppSnackBar.error(context, 'Upload failed. Please try again.');
    } finally {
      _photoCancelToken = null;
    }
  }

  void _retryPhotoUpload() {
    final path = _localPhotoPath;
    if (path != null) _uploadPhoto(path);
  }

  void _cancelPhotoUpload() => _photoCancelToken?.cancel();

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
              IconButtonCustom(icon: LucideIcons.arrowLeft, onPressed: _goBack),
              const SizedBox(height: AppSpacing.lg),
              const OnboardingProgressBar(currentStep: 0),
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
                    text: 'Tell us ',
                    style: TextStyle(color: AppColors.textPrimary)),
                TextSpan(
                  text: 'about yourself',
                  style: TextStyle(
                    foreground: Paint()
                      ..shader =
                          const LinearGradient(colors: AppColors.ctaGradient)
                              .createShader(const Rect.fromLTWH(0, 0, 220, 26)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Please enter your details',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(child: _buildPhotoPicker()),
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
                  label: 'Full Name',
                  child: AppTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    showFloatingLabel: false,
                    hint: 'Enter your full name',
                    readOnly: _sectionLocked,
                    errorText: _nameTouched && !_isNameValid
                        ? 'Enter 2-60 characters, no emoji'
                        : null,
                    prefixIcon: const Icon(LucideIcons.user,
                        color: AppColors.secondary, size: 20),
                    onChanged: (_) => setState(() => _nameTouched = true),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Email ID (optional)',
                  child: AppTextField(
                    label: 'Email ID',
                    controller: _emailController,
                    showFloatingLabel: false,
                    hint: 'you@email.com',
                    keyboardType: TextInputType.emailAddress,
                    readOnly: _sectionLocked,
                    errorText: _emailTouched && !_isEmailValid
                        ? 'Enter a valid email address'
                        : null,
                    prefixIcon: const Icon(LucideIcons.mail,
                        color: AppColors.secondary, size: 20),
                    onChanged: (_) => setState(() => _emailTouched = true),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Date of Birth',
                  child: AbsorbPointer(
                    absorbing: _sectionLocked,
                    child: DateOfBirthField(
                      value: _dateOfBirth,
                      onChanged: (value) =>
                          setState(() => _dateOfBirth = value),
                    ),
                  ),
                ),
                if (_dateOfBirth == null) ...[
                  const SizedBox(height: 4),
                  Text('Date of birth is required',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Gender',
                  child: AbsorbPointer(
                    absorbing: _sectionLocked,
                    child: GenderSelector(
                      selected: _gender,
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                  ),
                ),
                if (_gender == null) ...[
                  const SizedBox(height: 4),
                  Text('Please select a gender',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker() {
    final isUploading = _photoStatus == _PhotoStatus.uploading;
    final hasError = _photoStatus == _PhotoStatus.error;

    return GestureDetector(
      key: const Key('personal_details_photo_picker'),
      onTap: isUploading ? null : _pickPhoto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceMuted,
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.border,
                width: hasError ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildPhotoContent(),
          ),
          if (isUploading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      value: _photoProgress > 0 ? _photoProgress : null,
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
            ),
          if (isUploading)
            Positioned(
              bottom: -4,
              right: -4,
              child: _RoundIconButton(
                icon: LucideIcons.x,
                color: AppColors.error,
                onTap: _cancelPhotoUpload,
              ),
            )
          else if (hasError)
            Positioned(
              bottom: -4,
              right: -4,
              child: _RoundIconButton(
                icon: LucideIcons.refreshCw,
                color: AppColors.secondary,
                onTap: _retryPhotoUpload,
              ),
            )
          else if (!_sectionLocked)
            Positioned(
              bottom: -4,
              right: -4,
              child: _RoundIconButton(
                icon: LucideIcons.camera,
                color: AppColors.secondary,
                onTap: _pickPhoto,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoContent() {
    if (_localPhotoPath != null) {
      return Image.file(File(_localPhotoPath!), fit: BoxFit.cover);
    }
    if (_photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: _photoUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const Icon(
          LucideIcons.userCircle,
          size: 40,
          color: AppColors.textSecondary,
        ),
      );
    }
    return const Icon(LucideIcons.userCircle,
        size: 40, color: AppColors.textSecondary);
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
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
