import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/helpers/date_helper.dart';
import '../../../core/navigation/next_onboarding_step_resolver.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/validators/validators.dart';
import '../../../models/kyc/rider_kyc_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../repositories/document_verification/document_image_picker.dart';
import '../../../repositories/kyc/kyc_repository.dart';
import '../../../repositories/onboarding_status/onboarding_status_repository.dart';
import '../../../repositories/profile/profile_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/chips/filter_chip_custom.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/labeled_field.dart';
import '../widgets/onboarding_progress_bar.dart';

enum _DocState { idle, uploading, error }

/// Rider onboarding KYC step. Backend (`RiderKyc` model) bundles identity
/// verification AND bank payout details into one section behind a single
/// `PUT /rider/kyc` + two upload endpoints — there is no separate "Bank"
/// endpoint or onboarding lock, so this one screen covers government ID,
/// driving licence and bank details together, matching backend reality
/// rather than the generic 3-field spec (Aadhaar/PAN/Driving Licence)
/// initially assumed.
///
/// Document preview limitation: unlike the profile photo/selfie (which the
/// backend resolves to a signed URL on every read), `RiderKycService`
/// returns the raw private-bucket storage key for `governmentIdDocumentUrl`
/// / `drivingLicenseDocumentUrl` — there is no signed-URL endpoint for a
/// rider's own KYC documents. So a persisted (server-loaded) document can
/// only be shown as "uploaded" (a checkmark), never as an actual image
/// thumbnail; a real preview is only possible for the local file in the
/// same session, right after picking/uploading it.
class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  /// Mirrors the backend's `MAX_DOCUMENT_SIZE_BYTES`
  /// (`common/media/document-validation.ts`).
  static const _maxDocumentBytes = 5 * 1024 * 1024;

  final _govIdNumberController = TextEditingController();
  final _dlNumberController = TextEditingController();
  final _holderController = TextEditingController();
  final _accountController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _dlExpiryController = TextEditingController();

  bool _isLoading = true;
  String? _loadError;
  RiderKycModel? _original;

  GovernmentIdType? _govIdType;
  String? _govIdLocalPath;
  _DocState _govIdDocState = _DocState.idle;
  double _govIdProgress = 0;
  CancelToken? _govIdCancelToken;

  DateTime? _dlExpiry;
  String? _dlLocalPath;
  _DocState _dlDocState = _DocState.idle;
  double _dlProgress = 0;
  CancelToken? _dlCancelToken;

  bool _govIdNumberTouched = false;
  bool _dlNumberTouched = false;
  bool _holderTouched = false;
  bool _accountTouched = false;
  bool _ifscTouched = false;
  bool _bankNameTouched = false;

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
    _govIdNumberController.dispose();
    _dlNumberController.dispose();
    _holderController.dispose();
    _accountController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _dlExpiryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final kyc = await ref.read(kycRepositoryProvider).getKyc();
      if (!mounted) return;
      setState(() {
        _original = kyc;
        _govIdType = kyc?.governmentIdType;
        _govIdNumberController.text = kyc?.governmentIdNumber ?? '';
        _dlNumberController.text = kyc?.drivingLicenseNumber ?? '';
        _dlExpiry = kyc?.drivingLicenseExpiry;
        _dlExpiryController.text =
            _dlExpiry != null ? DateHelper.formatShort(_dlExpiry!) : '';
        _holderController.text = kyc?.bankAccountHolderName ?? '';
        _ifscController.text = kyc?.bankIfsc ?? '';
        _bankNameController.text = kyc?.bankName ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError =
            e is ApiException ? e.message : 'Could not load your KYC details.';
      });
    }
  }

  bool get _isGovIdNumberValid {
    final value = _govIdNumberController.text.trim();
    if (value.isEmpty) return false;
    return switch (_govIdType) {
      GovernmentIdType.aadhaar => Validators.isValidAadhaar(value),
      GovernmentIdType.pan => Validators.isValidPan(value),
      _ => true,
    };
  }

  bool get _hasGovIdDocument =>
      _govIdLocalPath != null || (_original?.hasGovernmentIdDocument ?? false);

  bool get _isGovIdSectionValid =>
      _govIdType != null && _isGovIdNumberValid && _hasGovIdDocument;

  bool get _isDlNumberValid => _dlNumberController.text.trim().length >= 5;

  bool get _isDlExpiryValid =>
      _dlExpiry != null && _dlExpiry!.isAfter(DateTime.now());

  bool get _hasDlDocument =>
      _dlLocalPath != null || (_original?.hasDrivingLicenseDocument ?? false);

  bool get _isDlSectionValid =>
      _isDlNumberValid && _isDlExpiryValid && _hasDlDocument;

  bool get _isHolderValid => _holderController.text.trim().isNotEmpty;

  bool get _accountTyped =>
      _accountController.text.trim().isNotEmpty ||
      _confirmAccountController.text.trim().isNotEmpty;

  bool get _isAccountValid {
    if (!_accountTyped) return _original?.hasBankAccountOnFile ?? false;
    final account = _accountController.text.trim();
    final confirm = _confirmAccountController.text.trim();
    return RegExp(r'^\d{9,18}$').hasMatch(account) && account == confirm;
  }

  bool get _isIfscValid => Validators.isValidIfsc(_ifscController.text);

  bool get _isBankNameValid => _bankNameController.text.trim().isNotEmpty;

  bool get _isBankSectionValid =>
      _isHolderValid && _isAccountValid && _isIfscValid && _isBankNameValid;

  bool get _isFormValid =>
      _isGovIdSectionValid && _isDlSectionValid && _isBankSectionValid;

  /// Whether any TEXT field (not documents, which upload and persist
  /// immediately on their own) differs from the last-loaded/saved state.
  /// Deliberately used instead of always calling `submit()` on Continue —
  /// the backend's `submit()` unconditionally resets `status` back to
  /// PENDING and clears any rejection reason on every call, even when the
  /// payload is identical, so re-submitting unchanged data would silently
  /// discard an APPROVED/REJECTED review outcome.
  bool get _isTextDirty {
    final o = _original;
    return _govIdType != o?.governmentIdType ||
        _govIdNumberController.text.trim() != (o?.governmentIdNumber ?? '') ||
        _dlNumberController.text.trim() != (o?.drivingLicenseNumber ?? '') ||
        _dlExpiry != o?.drivingLicenseExpiry ||
        _holderController.text.trim() != (o?.bankAccountHolderName ?? '') ||
        _accountTyped ||
        _ifscController.text.trim().toUpperCase() != (o?.bankIfsc ?? '') ||
        _bankNameController.text.trim() != (o?.bankName ?? '');
  }

  /// Unlike Personal Details/Address (`_canSave`, gated on dirty text
  /// fields), this is gated on the whole section being complete —
  /// documents upload and persist independently of the "Continue" button,
  /// so a rider revisiting an already-complete, unedited section must
  /// still be able to proceed.
  bool get _canContinue =>
      !_isLoading &&
      _loadError == null &&
      !_sectionLocked &&
      !_isSaving &&
      _isFormValid;

  Future<String> _resolveNextRoute() async {
    try {
      final status =
          await ref.read(onboardingStatusRepositoryProvider).getStatus();
      final profile = await ref.read(profileRepositoryProvider).getProfile();
      return NextOnboardingStepResolver.resolve(status, profile: profile);
    } catch (_) {
      return AppRoutes.vehicleSelection;
    }
  }

  Future<void> _onContinue() async {
    if (!_canContinue) return;
    setState(() {
      _isSaving = true;
      _isOffline = false;
    });
    try {
      if (_isTextDirty) {
        final o = _original;
        final accountTyped = _accountTyped;
        final updated = await ref.read(kycRepositoryProvider).submit(
              governmentIdType:
                  _govIdType != o?.governmentIdType ? _govIdType : null,
              governmentIdNumber:
                  _govIdNumberController.text.trim() !=
                          (o?.governmentIdNumber ?? '')
                      ? _govIdNumberController.text.trim()
                      : null,
              drivingLicenseNumber:
                  _dlNumberController.text.trim() !=
                          (o?.drivingLicenseNumber ?? '')
                      ? _dlNumberController.text.trim()
                      : null,
              drivingLicenseExpiry:
                  _dlExpiry != o?.drivingLicenseExpiry ? _dlExpiry : null,
              bankAccountHolderName:
                  _holderController.text.trim() !=
                          (o?.bankAccountHolderName ?? '')
                      ? _holderController.text.trim()
                      : null,
              bankAccountNumber:
                  accountTyped ? _accountController.text.trim() : null,
              confirmBankAccountNumber: accountTyped
                  ? _confirmAccountController.text.trim()
                  : null,
              bankIfsc: _ifscController.text.trim().toUpperCase() !=
                      (o?.bankIfsc ?? '')
                  ? _ifscController.text.trim().toUpperCase()
                  : null,
              bankName: _bankNameController.text.trim() != (o?.bankName ?? '')
                  ? _bankNameController.text.trim()
                  : null,
            );
        if (!mounted) return;
        setState(() {
          _original = updated;
          _accountController.clear();
          _confirmAccountController.clear();
        });
      }
      if (!mounted) return;
      Get.toNamed(await _resolveNextRoute());
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
          onAction: e.statusCode == 403 ? null : _onContinue,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackBar.error(context, 'Something went wrong. Please try again.');
    }
  }

  Future<String?> _pickDocumentSource() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(LucideIcons.camera, color: AppColors.secondary),
                title: Text('Take Photo', style: AppTypography.bodyMedium),
                onTap: () => Navigator.of(sheetContext).pop('camera'),
              ),
              ListTile(
                leading:
                    const Icon(LucideIcons.image, color: AppColors.secondary),
                title: Text('Choose from Gallery',
                    style: AppTypography.bodyMedium),
                onTap: () => Navigator.of(sheetContext).pop('gallery'),
              ),
              ListTile(
                leading: const Icon(LucideIcons.fileText,
                    color: AppColors.secondary),
                title: Text('Upload PDF', style: AppTypography.bodyMedium),
                onTap: () => Navigator.of(sheetContext).pop('pdf'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null) return null;
    switch (choice) {
      case 'camera':
        return ref
            .read(documentImagePickerProvider)
            .pickImage(ImageSource.camera);
      case 'gallery':
        return ref
            .read(documentImagePickerProvider)
            .pickImage(ImageSource.gallery);
      case 'pdf':
        return ref.read(kycDocumentFilePickerProvider).pickPdf();
      default:
        return null;
    }
  }

  Future<void> _pickGovernmentIdDocument() async {
    if (_sectionLocked || _govIdDocState == _DocState.uploading) return;
    final path = await _pickDocumentSource();
    if (path == null) return;
    await _uploadGovernmentIdDocument(path);
  }

  Future<void> _uploadGovernmentIdDocument(String path) async {
    final file = File(path);
    if (await file.length() > _maxDocumentBytes) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        'File exceeds the 5MB limit. Please choose a smaller file.',
      );
      return;
    }
    setState(() {
      _govIdLocalPath = path;
      _govIdDocState = _DocState.uploading;
      _govIdProgress = 0;
    });
    final cancelToken = CancelToken();
    _govIdCancelToken = cancelToken;
    try {
      final updated =
          await ref.read(kycRepositoryProvider).uploadGovernmentIdDocument(
                file,
                cancelToken: cancelToken,
                onSendProgress: (sent, total) {
                  if (!mounted || total <= 0) return;
                  setState(() => _govIdProgress = sent / total);
                },
              );
      if (!mounted) return;
      setState(() {
        _original = updated;
        _govIdDocState = _DocState.idle;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == DioExceptionType.cancel.name) {
        setState(() {
          _govIdDocState = _DocState.idle;
          _govIdLocalPath = null;
        });
        return;
      }
      if (e.statusCode == 403) {
        setState(() {
          _sectionLocked = true;
          _govIdDocState = _DocState.idle;
          _govIdLocalPath = null;
        });
        return;
      }
      setState(() => _govIdDocState = _DocState.error);
      AppSnackBar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _govIdDocState = _DocState.error);
      AppSnackBar.error(context, 'Upload failed. Please try again.');
    } finally {
      _govIdCancelToken = null;
    }
  }

  void _retryGovernmentIdUpload() {
    final path = _govIdLocalPath;
    if (path != null) _uploadGovernmentIdDocument(path);
  }

  void _cancelGovernmentIdUpload() => _govIdCancelToken?.cancel();

  Future<void> _pickDrivingLicenseDocument() async {
    if (_sectionLocked || _dlDocState == _DocState.uploading) return;
    final path = await _pickDocumentSource();
    if (path == null) return;
    await _uploadDrivingLicenseDocument(path);
  }

  Future<void> _uploadDrivingLicenseDocument(String path) async {
    final file = File(path);
    if (await file.length() > _maxDocumentBytes) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        'File exceeds the 5MB limit. Please choose a smaller file.',
      );
      return;
    }
    setState(() {
      _dlLocalPath = path;
      _dlDocState = _DocState.uploading;
      _dlProgress = 0;
    });
    final cancelToken = CancelToken();
    _dlCancelToken = cancelToken;
    try {
      final updated =
          await ref.read(kycRepositoryProvider).uploadDrivingLicenseDocument(
                file,
                cancelToken: cancelToken,
                onSendProgress: (sent, total) {
                  if (!mounted || total <= 0) return;
                  setState(() => _dlProgress = sent / total);
                },
              );
      if (!mounted) return;
      setState(() {
        _original = updated;
        _dlDocState = _DocState.idle;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == DioExceptionType.cancel.name) {
        setState(() {
          _dlDocState = _DocState.idle;
          _dlLocalPath = null;
        });
        return;
      }
      if (e.statusCode == 403) {
        setState(() {
          _sectionLocked = true;
          _dlDocState = _DocState.idle;
          _dlLocalPath = null;
        });
        return;
      }
      setState(() => _dlDocState = _DocState.error);
      AppSnackBar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _dlDocState = _DocState.error);
      AppSnackBar.error(context, 'Upload failed. Please try again.');
    } finally {
      _dlCancelToken = null;
    }
  }

  void _retryDrivingLicenseUpload() {
    final path = _dlLocalPath;
    if (path != null) _uploadDrivingLicenseDocument(path);
  }

  void _cancelDrivingLicenseUpload() => _dlCancelToken?.cancel();

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dlExpiry ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(primary: AppColors.secondary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dlExpiry = picked;
        _dlExpiryController.text = DateHelper.formatShort(picked);
      });
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. If you leave now, they will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _handleBackPressed() async {
    if (!_isTextDirty || await _confirmDiscardChanges()) {
      if (mounted) Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isTextDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscardChanges() && mounted) Get.back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                IconButtonCustom(
                    icon: LucideIcons.arrowLeft, onPressed: _handleBackPressed),
                const SizedBox(height: AppSpacing.lg),
                const OnboardingProgressBar(currentStep: 2),
                const SizedBox(height: AppSpacing.lg),
                Expanded(child: _buildBody(context)),
                if (!_isLoading && _loadError == null) ...[
                  PrimaryCtaButton(
                    label: 'Continue',
                    trailingIcon: LucideIcons.arrowRight,
                    isLoading: _isSaving,
                    onPressed: _canContinue ? _onContinue : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
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
            Text('Could not load your KYC details', style: AppTypography.body),
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
                    text: 'Verify your ',
                    style: TextStyle(color: AppColors.textPrimary)),
                TextSpan(
                  text: 'identity',
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
            'Government ID, driving licence and payout details',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_original?.status == KycDocumentStatus.rejected &&
              _original?.rejectionReason != null) ...[
            _InfoBanner(
              icon: LucideIcons.alertCircle,
              color: AppColors.error,
              message: 'Rejected: ${_original!.rejectionReason}',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
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
              onAction: _onContinue,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _buildGovernmentIdCard(),
          const SizedBox(height: AppSpacing.md),
          _buildDrivingLicenseCard(),
          const SizedBox(height: AppSpacing.md),
          _buildBankDetailsCard(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildGovernmentIdCard() {
    return _SectionCard(
      title: 'Government ID',
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final type in GovernmentIdType.values)
              FilterChipCustom(
                label: type.label,
                selected: _govIdType == type,
                onTap: _sectionLocked
                    ? () {}
                    : () => setState(() => _govIdType = type),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LabeledField(
          label: 'ID Number',
          child: AppTextField(
            label: 'ID Number',
            controller: _govIdNumberController,
            showFloatingLabel: false,
            hint: _govIdType == GovernmentIdType.aadhaar
                ? '12-digit Aadhaar number'
                : _govIdType == GovernmentIdType.pan
                    ? 'ABCDE1234F'
                    : 'Enter ID number',
            readOnly: _sectionLocked,
            keyboardType: _govIdType == GovernmentIdType.aadhaar
                ? TextInputType.number
                : TextInputType.text,
            textCapitalization: _govIdType == GovernmentIdType.pan
                ? TextCapitalization.characters
                : TextCapitalization.none,
            inputFormatters: _govIdType == GovernmentIdType.aadhaar
                ? [FilteringTextInputFormatter.digitsOnly]
                : _govIdType == GovernmentIdType.pan
                    ? [_UpperCaseTextFormatter()]
                    : null,
            maxLength: _govIdType == GovernmentIdType.aadhaar ? 12 : null,
            errorText: _govIdNumberTouched && !_isGovIdNumberValid
                ? (_govIdType == GovernmentIdType.aadhaar
                    ? 'Enter a valid 12-digit Aadhaar number'
                    : _govIdType == GovernmentIdType.pan
                        ? 'Enter a valid PAN (e.g. ABCDE1234F)'
                        : 'ID number is required')
                : null,
            prefixIcon: const Icon(LucideIcons.fingerprint,
                color: AppColors.secondary, size: 20),
            onChanged: (_) => setState(() => _govIdNumberTouched = true),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _DocumentUploadRow(
          title: 'ID Document',
          isUploaded: _original?.hasGovernmentIdDocument ?? false,
          localPath: _govIdLocalPath,
          state: _govIdDocState,
          progress: _govIdProgress,
          locked: _sectionLocked,
          onUpload: _pickGovernmentIdDocument,
          onCancel: _cancelGovernmentIdUpload,
          onRetry: _retryGovernmentIdUpload,
        ),
      ],
    );
  }

  Widget _buildDrivingLicenseCard() {
    return _SectionCard(
      title: 'Driving Licence',
      children: [
        LabeledField(
          label: 'Licence Number',
          child: AppTextField(
            label: 'Licence Number',
            controller: _dlNumberController,
            showFloatingLabel: false,
            hint: 'e.g. DL0420110149646',
            readOnly: _sectionLocked,
            textCapitalization: TextCapitalization.characters,
            errorText: _dlNumberTouched && !_isDlNumberValid
                ? 'Enter a valid licence number'
                : null,
            prefixIcon: const Icon(LucideIcons.contact,
                color: AppColors.secondary, size: 20),
            onChanged: (_) => setState(() => _dlNumberTouched = true),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LabeledField(
          label: 'Expiry Date',
          child: AbsorbPointer(
            absorbing: _sectionLocked,
            child: AppTextField(
              label: 'Expiry Date',
              controller: _dlExpiryController,
              showFloatingLabel: false,
              hint: 'Select expiry date',
              readOnly: true,
              onTap: _pickExpiryDate,
              prefixIcon: const Icon(LucideIcons.calendar,
                  color: AppColors.secondary, size: 20),
              suffixIcon: const Icon(LucideIcons.calendarDays,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ),
        if (_dlExpiry != null && !_isDlExpiryValid) ...[
          const SizedBox(height: 4),
          Text('Expiry date must be in the future',
              style:
                  AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: AppSpacing.md),
        _DocumentUploadRow(
          title: 'Licence Document',
          isUploaded: _original?.hasDrivingLicenseDocument ?? false,
          localPath: _dlLocalPath,
          state: _dlDocState,
          progress: _dlProgress,
          locked: _sectionLocked,
          onUpload: _pickDrivingLicenseDocument,
          onCancel: _cancelDrivingLicenseUpload,
          onRetry: _retryDrivingLicenseUpload,
        ),
      ],
    );
  }

  Widget _buildBankDetailsCard() {
    return _SectionCard(
      title: 'Bank Details',
      children: [
        LabeledField(
          label: 'Account Holder Name',
          child: AppTextField(
            label: 'Account Holder Name',
            controller: _holderController,
            showFloatingLabel: false,
            hint: 'Name as per bank records',
            readOnly: _sectionLocked,
            textCapitalization: TextCapitalization.words,
            errorText: _holderTouched && !_isHolderValid
                ? 'Account holder name is required'
                : null,
            prefixIcon: const Icon(LucideIcons.user,
                color: AppColors.secondary, size: 20),
            onChanged: (_) => setState(() => _holderTouched = true),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_original?.hasBankAccountOnFile ?? false) ...[
          Text(
            'On file: ${_original!.bankAccountNumberMasked}. Leave blank to keep it unchanged.',
            style:
                AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        LabeledField(
          label: 'Account Number',
          child: AppTextField(
            label: 'Account Number',
            controller: _accountController,
            showFloatingLabel: false,
            hint: 'Enter account number',
            readOnly: _sectionLocked,
            keyboardType: TextInputType.number,
            maxLength: 18,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: _accountTouched && !_isAccountValid
                ? 'Enter a valid account number'
                : null,
            prefixIcon: const Icon(LucideIcons.creditCard,
                color: AppColors.secondary, size: 20),
            onChanged: (_) => setState(() => _accountTouched = true),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LabeledField(
          label: 'Confirm Account Number',
          child: AppTextField(
            label: 'Confirm Account Number',
            controller: _confirmAccountController,
            showFloatingLabel: false,
            hint: 'Re-enter account number',
            readOnly: _sectionLocked,
            keyboardType: TextInputType.number,
            maxLength: 18,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: _accountTouched && !_isAccountValid
                ? 'Account numbers do not match'
                : null,
            prefixIcon: const Icon(LucideIcons.checkCircle2,
                color: AppColors.secondary, size: 20),
            onChanged: (_) => setState(() => _accountTouched = true),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LabeledField(
          label: 'IFSC Code',
          child: AppTextField(
            label: 'IFSC Code',
            controller: _ifscController,
            showFloatingLabel: false,
            hint: 'e.g. HDFC0001234',
            readOnly: _sectionLocked,
            maxLength: 11,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              _UpperCaseTextFormatter(),
              FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
            ],
            errorText: _ifscTouched && !_isIfscValid
                ? 'Enter a valid 11-character IFSC code'
                : null,
            prefixIcon: const Icon(LucideIcons.landmark,
                color: AppColors.secondary, size: 20),
            onChanged: (_) => setState(() => _ifscTouched = true),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LabeledField(
          label: 'Bank Name',
          child: AppTextField(
            label: 'Bank Name',
            controller: _bankNameController,
            showFloatingLabel: false,
            hint: 'e.g. HDFC Bank',
            readOnly: _sectionLocked,
            textCapitalization: TextCapitalization.words,
            errorText: _bankNameTouched && !_isBankNameValid
                ? 'Bank name is required'
                : null,
            prefixIcon: const Icon(LucideIcons.building2,
                color: AppColors.secondary, size: 20),
            onChanged: (_) => setState(() => _bankNameTouched = true),
          ),
        ),
      ],
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

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
          Text(title,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _DocumentUploadRow extends StatelessWidget {
  final String title;
  final bool isUploaded;
  final String? localPath;
  final _DocState state;
  final double progress;
  final bool locked;
  final VoidCallback onUpload;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  const _DocumentUploadRow({
    required this.title,
    required this.isUploaded,
    required this.localPath,
    required this.state,
    required this.progress,
    required this.locked,
    required this.onUpload,
    required this.onCancel,
    required this.onRetry,
  });

  bool get _isLocalPdf => (localPath ?? '').toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildPreview(),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium),
                const SizedBox(height: 2),
                Text(_statusLabel,
                    style: AppTypography.caption
                        .copyWith(color: _statusColor)),
                if (state == _DocState.uploading) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      minHeight: 4,
                      backgroundColor: AppColors.border,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildAction(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    const size = 44.0;
    if (localPath != null && !_isLocalPdf) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Image.file(File(localPath!),
            width: size, height: size, fit: BoxFit.cover),
      );
    }
    final showCheck = isUploaded && state != _DocState.uploading;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(
        showCheck ? LucideIcons.checkCircle2 : LucideIcons.fileText,
        color: showCheck ? AppColors.success : AppColors.textSecondary,
        size: 22,
      ),
    );
  }

  String get _statusLabel => switch (state) {
        _DocState.uploading => 'Uploading… ${(progress * 100).round()}%',
        _DocState.error => 'Upload failed',
        _DocState.idle => isUploaded ? 'Uploaded' : 'Not uploaded',
      };

  Color get _statusColor => switch (state) {
        _DocState.uploading => AppColors.secondary,
        _DocState.error => AppColors.error,
        _DocState.idle => isUploaded ? AppColors.success : AppColors.textSecondary,
      };

  Widget _buildAction() {
    if (state == _DocState.uploading) {
      return TextButton(
        onPressed: onCancel,
        child: const Text('Cancel'),
      );
    }
    if (state == _DocState.error) {
      return TextButton(onPressed: onRetry, child: const Text('Retry'));
    }
    if (locked) return const SizedBox.shrink();
    return TextButton(
      onPressed: onUpload,
      child: Text(isUploaded ? 'Replace' : 'Upload'),
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
