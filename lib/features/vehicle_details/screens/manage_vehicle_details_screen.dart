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
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/vehicle/rider_vehicle_model.dart';
import '../../../repositories/document_verification/document_image_picker.dart';
import '../../../repositories/vehicle/vehicle_repository.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/chips/filter_chip_custom.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
import '../../profile/widgets/account_screen_components.dart';

enum _DocState { idle, uploading, error }

/// Vehicle info for the active/approved rider, reached from Profile.
///
/// Mirrors `VehicleRegistrationScreen`'s (onboarding) data logic exactly —
/// same backend, same `RiderVehicle` model, same real constraint: there is
/// no endpoint to edit an existing vehicle's fields in place, and once
/// onboarding is no longer IN_PROGRESS/CLARIFICATION_REQUIRED the backend
/// locks the whole VEHICLE section (`RiderOnboardingLockService`) — so for
/// an active rider, registering a *new* vehicle or re-uploading a document
/// will genuinely be rejected (403) by the backend. Rather than fabricate a
/// working "edit" flow, this screen shows the real vehicle read-only and
/// only reveals the create/upload actions when the backend actually allows
/// them, surfacing its real lock message if not.
class ManageVehicleDetailsScreen extends ConsumerStatefulWidget {
  const ManageVehicleDetailsScreen({super.key});

  @override
  ConsumerState<ManageVehicleDetailsScreen> createState() =>
      _ManageVehicleDetailsScreenState();
}

class _ManageVehicleDetailsScreenState
    extends ConsumerState<ManageVehicleDetailsScreen> {
  static const _maxDocumentBytes = 5 * 1024 * 1024;

  bool _isLoading = true;
  String? _loadError;
  List<RiderVehicleModel> _vehicles = [];
  bool _showCreateForm = false;

  VehicleType? _type;
  final _regNumberController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _rcNumberController = TextEditingController();
  DateTime? _insuranceExpiry;
  final _insuranceExpiryController = TextEditingController();
  bool _regNumberTouched = false;
  bool _isCreating = false;

  _DocState _rcDocState = _DocState.idle;
  String? _rcLocalPath;
  double _rcProgress = 0;
  CancelToken? _rcCancelToken;

  _DocState _insuranceDocState = _DocState.idle;
  String? _insuranceLocalPath;
  double _insuranceProgress = 0;
  CancelToken? _insuranceCancelToken;

  bool _sectionLocked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _regNumberController.dispose();
    _insuranceNumberController.dispose();
    _rcNumberController.dispose();
    _insuranceExpiryController.dispose();
    super.dispose();
  }

  RiderVehicleModel? get _current {
    if (_vehicles.isEmpty) return null;
    for (final v in _vehicles) {
      if (v.isActive) return v;
    }
    return _vehicles.first;
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final vehicles = await ref.read(vehicleRepositoryProvider).listVehicles();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _showCreateForm = vehicles.isEmpty;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e is ApiException ? e.message : 'Could not load your vehicle.';
      });
    }
  }

  bool get _isRegNumberValid => _regNumberController.text.trim().length >= 4;

  bool get _isInsuranceExpiryValid =>
      _insuranceExpiryController.text.trim().isEmpty ||
      (_insuranceExpiry != null && _insuranceExpiry!.isAfter(DateTime.now()));

  bool get _canCreate =>
      !_isCreating &&
      !_sectionLocked &&
      _type != null &&
      _isRegNumberValid &&
      _isInsuranceExpiryValid;

  Future<void> _pickInsuranceExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _insuranceExpiry ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context).colorScheme.copyWith(primary: AppColors.secondary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _insuranceExpiry = picked;
        _insuranceExpiryController.text = DateHelper.formatShort(picked);
      });
    }
  }

  Future<void> _onCreate() async {
    if (!_canCreate) return;
    setState(() => _isCreating = true);
    try {
      final vehicle = await ref.read(vehicleRepositoryProvider).createVehicle(
            type: _type!,
            registrationNumber: _regNumberController.text.trim().toUpperCase(),
            insuranceNumber: _insuranceNumberController.text.trim().isEmpty
                ? null
                : _insuranceNumberController.text.trim(),
            insuranceExpiry: _insuranceExpiry,
            rcNumber: _rcNumberController.text.trim().isEmpty
                ? null
                : _rcNumberController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _vehicles = [vehicle, ..._vehicles];
        _showCreateForm = false;
        _isCreating = false;
        _type = null;
        _regNumberController.clear();
        _insuranceNumberController.clear();
        _rcNumberController.clear();
        _insuranceExpiry = null;
        _insuranceExpiryController.clear();
        _regNumberTouched = false;
      });
      AppSnackBar.success(context, 'Vehicle submitted for verification');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreating = false;
        _sectionLocked = e.statusCode == 403;
      });
      AppSnackBar.error(
        context,
        e.statusCode == 403
            ? e.message
            : e.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      AppSnackBar.error(context, 'Something went wrong. Please try again.');
    }
  }

  Future<String?> _pickDocumentSource() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera, color: AppColors.secondary),
                title: Text('Take Photo', style: AppTypography.bodyMedium),
                onTap: () => Navigator.of(sheetContext).pop('camera'),
              ),
              ListTile(
                leading: const Icon(LucideIcons.image, color: AppColors.secondary),
                title: Text('Choose from Gallery', style: AppTypography.bodyMedium),
                onTap: () => Navigator.of(sheetContext).pop('gallery'),
              ),
              ListTile(
                leading: const Icon(LucideIcons.fileText, color: AppColors.secondary),
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
        return ref.read(documentImagePickerProvider).pickImage(ImageSource.camera);
      case 'gallery':
        return ref.read(documentImagePickerProvider).pickImage(ImageSource.gallery);
      case 'pdf':
        return ref.read(kycDocumentFilePickerProvider).pickPdf();
      default:
        return null;
    }
  }

  Future<void> _pickRcDocument() async {
    if (_sectionLocked || _rcDocState == _DocState.uploading) return;
    final path = await _pickDocumentSource();
    if (path == null) return;
    await _uploadRcDocument(path);
  }

  Future<void> _uploadRcDocument(String path) async {
    final vehicle = _current;
    if (vehicle == null) return;
    final file = File(path);
    if (await file.length() > _maxDocumentBytes) {
      if (!mounted) return;
      AppSnackBar.error(
          context, 'File exceeds the 5MB limit. Please choose a smaller file.');
      return;
    }
    setState(() {
      _rcLocalPath = path;
      _rcDocState = _DocState.uploading;
      _rcProgress = 0;
    });
    final cancelToken = CancelToken();
    _rcCancelToken = cancelToken;
    try {
      final updated = await ref.read(vehicleRepositoryProvider).uploadRcDocument(
        vehicle.id,
        file,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          setState(() => _rcProgress = sent / total);
        },
      );
      if (!mounted) return;
      setState(() {
        _vehicles = _replaceVehicle(updated);
        _rcDocState = _DocState.idle;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == DioExceptionType.cancel.name) {
        setState(() {
          _rcDocState = _DocState.idle;
          _rcLocalPath = null;
        });
        return;
      }
      if (e.statusCode == 403) {
        setState(() {
          _sectionLocked = true;
          _rcDocState = _DocState.idle;
          _rcLocalPath = null;
        });
        AppSnackBar.error(context, e.message);
        return;
      }
      setState(() => _rcDocState = _DocState.error);
      AppSnackBar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _rcDocState = _DocState.error);
      AppSnackBar.error(context, 'Upload failed. Please try again.');
    } finally {
      _rcCancelToken = null;
    }
  }

  void _retryRcUpload() {
    final path = _rcLocalPath;
    if (path != null) _uploadRcDocument(path);
  }

  void _cancelRcUpload() => _rcCancelToken?.cancel();

  Future<void> _pickInsuranceDocument() async {
    if (_sectionLocked || _insuranceDocState == _DocState.uploading) return;
    final path = await _pickDocumentSource();
    if (path == null) return;
    await _uploadInsuranceDocument(path);
  }

  Future<void> _uploadInsuranceDocument(String path) async {
    final vehicle = _current;
    if (vehicle == null) return;
    final file = File(path);
    if (await file.length() > _maxDocumentBytes) {
      if (!mounted) return;
      AppSnackBar.error(
          context, 'File exceeds the 5MB limit. Please choose a smaller file.');
      return;
    }
    setState(() {
      _insuranceLocalPath = path;
      _insuranceDocState = _DocState.uploading;
      _insuranceProgress = 0;
    });
    final cancelToken = CancelToken();
    _insuranceCancelToken = cancelToken;
    try {
      final updated =
          await ref.read(vehicleRepositoryProvider).uploadInsuranceDocument(
        vehicle.id,
        file,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          setState(() => _insuranceProgress = sent / total);
        },
      );
      if (!mounted) return;
      setState(() {
        _vehicles = _replaceVehicle(updated);
        _insuranceDocState = _DocState.idle;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == DioExceptionType.cancel.name) {
        setState(() {
          _insuranceDocState = _DocState.idle;
          _insuranceLocalPath = null;
        });
        return;
      }
      if (e.statusCode == 403) {
        setState(() {
          _sectionLocked = true;
          _insuranceDocState = _DocState.idle;
          _insuranceLocalPath = null;
        });
        AppSnackBar.error(context, e.message);
        return;
      }
      setState(() => _insuranceDocState = _DocState.error);
      AppSnackBar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _insuranceDocState = _DocState.error);
      AppSnackBar.error(context, 'Upload failed. Please try again.');
    } finally {
      _insuranceCancelToken = null;
    }
  }

  void _retryInsuranceUpload() {
    final path = _insuranceLocalPath;
    if (path != null) _uploadInsuranceDocument(path);
  }

  void _cancelInsuranceUpload() => _insuranceCancelToken?.cancel();

  List<RiderVehicleModel> _replaceVehicle(RiderVehicleModel updated) => [
        for (final v in _vehicles) v.id == updated.id ? updated : v,
      ];

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
              const AccountScreenHeader(
                title: 'Vehicle Details',
                subtitle: 'View your registered delivery vehicle.',
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const PageLoadingShimmer(padding: EdgeInsets.zero, itemCount: 2);
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load your vehicle', style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
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
          if (_sectionLocked) ...[
            const AccountInfoBanner(
              icon: LucideIcons.lock,
              title: 'Editing is closed',
              message:
                  'Your vehicle was verified at onboarding and can no longer be changed here. Contact support to update it.',
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_current != null) _buildVehicleSummary(_current!),
          if (_current == null) ...[
            const AccountInfoBanner(
              icon: LucideIcons.bike,
              title: 'No vehicle on file',
              message: 'Register the vehicle you deliver with.',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_current != null &&
              _current!.status == VehicleDocumentStatus.rejected &&
              !_showCreateForm) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _showCreateForm = true),
                child: const Text('Register a different vehicle'),
              ),
            ),
          ],
          if (_showCreateForm) ...[
            const SizedBox(height: AppSpacing.md),
            _buildCreateForm(),
          ],
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.manageDocuments),
              icon: const Icon(LucideIcons.fileText, size: 18),
              label: const Text('Manage documents'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildVehicleSummary(RiderVehicleModel vehicle) {
    return AccountSectionCard(
      title: 'Vehicle information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vehicle.status == VehicleDocumentStatus.rejected &&
              vehicle.rejectionReason != null) ...[
            AccountInfoBanner(
              icon: LucideIcons.alertCircle,
              title: 'Rejected',
              message: vehicle.rejectionReason!,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _SummaryRow(label: 'Type', value: vehicle.type.label),
          _SummaryRow(label: 'Registration Number', value: vehicle.registrationNumber),
          _SummaryRow(label: 'Status', value: _statusLabel(vehicle.status)),
          if (vehicle.insuranceNumber != null)
            _SummaryRow(label: 'Insurance Number', value: vehicle.insuranceNumber!),
          if (vehicle.insuranceExpiry != null)
            _SummaryRow(
              label: 'Insurance Expiry',
              value: DateHelper.formatShort(vehicle.insuranceExpiry!),
              valueColor: vehicle.isInsuranceExpired ? AppColors.error : null,
            ),
          if (vehicle.rcNumber != null)
            _SummaryRow(label: 'RC Number', value: vehicle.rcNumber!),
          const SizedBox(height: AppSpacing.md),
          _DocumentUploadRow(
            title: 'RC Document',
            isUploaded: vehicle.hasRcDocument,
            localPath: _rcLocalPath,
            state: _rcDocState,
            progress: _rcProgress,
            locked: _sectionLocked,
            onUpload: _pickRcDocument,
            onCancel: _cancelRcUpload,
            onRetry: _retryRcUpload,
          ),
          const SizedBox(height: AppSpacing.md),
          _DocumentUploadRow(
            title: 'Insurance Document',
            isUploaded: vehicle.hasInsuranceDocument,
            localPath: _insuranceLocalPath,
            state: _insuranceDocState,
            progress: _insuranceProgress,
            locked: _sectionLocked,
            onUpload: _pickInsuranceDocument,
            onCancel: _cancelInsuranceUpload,
            onRetry: _retryInsuranceUpload,
          ),
        ],
      ),
    );
  }

  String _statusLabel(VehicleDocumentStatus status) => switch (status) {
        VehicleDocumentStatus.approved => 'Approved',
        VehicleDocumentStatus.pending => 'Pending verification',
        VehicleDocumentStatus.rejected => 'Rejected',
        VehicleDocumentStatus.unknown => 'Unknown',
      };

  Widget _buildCreateForm() {
    return AccountSectionCard(
      title: _vehicles.isEmpty ? 'Register your vehicle' : 'Register a new vehicle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final type in VehicleType.values)
                FilterChipCustom(
                  label: type.label,
                  selected: _type == type,
                  onTap: _sectionLocked ? () {} : () => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Registration number',
            hint: 'e.g. KA01AB1234',
            controller: _regNumberController,
            readOnly: _sectionLocked,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [_UpperCaseTextFormatter()],
            errorText: _regNumberTouched && !_isRegNumberValid
                ? 'Enter a valid registration number'
                : null,
            prefixIcon: const Icon(LucideIcons.creditCard,
                color: AppColors.secondary, size: 20),
            onChanged: (_) => setState(() => _regNumberTouched = true),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Insurance number (optional)',
            hint: 'Policy number',
            controller: _insuranceNumberController,
            readOnly: _sectionLocked,
            prefixIcon: const Icon(LucideIcons.shieldCheck,
                color: AppColors.secondary, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          AbsorbPointer(
            absorbing: _sectionLocked,
            child: AppTextField(
              label: 'Insurance expiry (optional)',
              hint: 'Select expiry date',
              controller: _insuranceExpiryController,
              readOnly: true,
              onTap: _pickInsuranceExpiry,
              prefixIcon: const Icon(LucideIcons.calendar,
                  color: AppColors.secondary, size: 20),
              suffixIcon: const Icon(LucideIcons.calendarDays,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
          if (!_isInsuranceExpiryValid) ...[
            const SizedBox(height: 4),
            Text('Expiry date must be in the future',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'RC number (optional)',
            hint: 'Registration certificate number',
            controller: _rcNumberController,
            readOnly: _sectionLocked,
            prefixIcon: const Icon(LucideIcons.fileText,
                color: AppColors.secondary, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryCtaButton(
            label: 'Save vehicle details',
            trailingIcon: LucideIcons.check,
            isLoading: _isCreating,
            onPressed: _canCreate ? _onCreate : null,
          ),
        ],
      ),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label,
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium
                  .copyWith(color: valueColor ?? AppColors.textPrimary),
            ),
          ),
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
                    style: AppTypography.caption.copyWith(color: _statusColor)),
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
        child: Image.file(File(localPath!), width: size, height: size, fit: BoxFit.cover),
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
      return TextButton(onPressed: onCancel, child: const Text('Cancel'));
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
