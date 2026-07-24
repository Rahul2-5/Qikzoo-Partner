import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
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
import '../../../models/profile/partner_profile_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../repositories/onboarding_status/onboarding_status_repository.dart';
import '../../../repositories/profile/profile_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/current_location_tile.dart';
import '../widgets/labeled_field.dart';
import '../widgets/onboarding_progress_bar.dart';

/// Picks the best available field on a reverse-geocoded [Placemark] for
/// Address Line 1: street first, falling back to name, then subLocality,
/// so a GPS lookup with a sparse platform result still fills something in
/// rather than leaving the field blank. Pulled out as a standalone
/// function (rather than inlined in the widget) so it's unit-testable
/// without any platform channel — [Placemark] itself is a plain data
/// class the geocoding package lets you construct directly in tests.
String addressLine1FromPlacemark(Placemark placemark) {
  if (placemark.street?.trim().isNotEmpty ?? false) {
    return placemark.street!.trim();
  }
  if (placemark.name?.trim().isNotEmpty ?? false) {
    return placemark.name!.trim();
  }
  return placemark.subLocality?.trim() ?? '';
}

/// Rider onboarding Address step. Backend (`Rider` model) stores exactly
/// one residential address — no permanent/current split, no country
/// field — so this screen deliberately has no "Permanent Address" /"Same
/// as Current Address" section: there is nowhere on the backend to
/// persist a second address, and inventing local-only storage for it
/// would silently discard data on save. Country is shown fixed to
/// "India" (not sent to the backend — there's no field for it) since
/// riders are onboarded domestically only.
class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  bool _isLoading = true;
  String? _loadError;
  PartnerProfileModel? _original;

  double? _addressLat;
  double? _addressLng;

  bool _isLocating = false;
  String? _locationError;
  bool _locationPermanentlyDenied = false;

  bool _line1Touched = false;
  bool _cityTouched = false;
  bool _stateTouched = false;
  bool _pincodeTouched = false;

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
    _line1Controller.dispose();
    _line2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
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
        _line1Controller.text = profile.addressLine1 ?? '';
        _line2Controller.text = profile.addressLine2 ?? '';
        _landmarkController.text = profile.landmark ?? '';
        _cityController.text = profile.city ?? '';
        _stateController.text = profile.state ?? '';
        _pincodeController.text = profile.pincode ?? '';
        _addressLat = profile.addressLat;
        _addressLng = profile.addressLng;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError =
            e is ApiException ? e.message : 'Could not load your address.';
      });
    }
  }

  String get _line1 => Validators.normalizeWhitespace(_line1Controller.text);
  String get _line2 => Validators.normalizeWhitespace(_line2Controller.text);
  String get _landmark =>
      Validators.normalizeWhitespace(_landmarkController.text);
  String get _city => Validators.normalizeWhitespace(_cityController.text);
  String get _state => Validators.normalizeWhitespace(_stateController.text);
  String get _pincode => _pincodeController.text.trim();

  bool get _isLine1Valid => _line1.isNotEmpty;
  bool get _isCityValid => _city.isNotEmpty;
  bool get _isStateValid => _state.isNotEmpty;
  bool get _isPincodeValid => Validators.isValidPincode(_pincode);

  bool get _isFormValid =>
      _isLine1Valid && _isCityValid && _isStateValid && _isPincodeValid;

  bool get _isDirty {
    final original = _original;
    if (original == null) return false;
    return _line1 != (original.addressLine1 ?? '') ||
        _line2 != (original.addressLine2 ?? '') ||
        _landmark != (original.landmark ?? '') ||
        _city != (original.city ?? '') ||
        _state != (original.state ?? '') ||
        _pincode != (original.pincode ?? '');
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
      return AppRoutes.vehicleSelection;
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
          await ref.read(profileRepositoryProvider).updateAddress(
                addressLine1: _line1,
                addressLine2: _line2.isEmpty ? null : _line2,
                landmark: _landmark.isEmpty ? null : _landmark,
                city: _city,
                state: _state,
                pincode: _pincode,
                addressLat: _addressLat,
                addressLng: _addressLng,
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
        _isOffline = e.code == 'connectionError';
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

  Future<void> _goBack() =>
      popOnboardingOrGoTo(context, AppRoutes.personalInfo);

  Future<void> _useCurrentLocation() async {
    if (_sectionLocked || _isLocating) return;
    setState(() {
      _isLocating = true;
      _locationError = null;
      _locationPermanentlyDenied = false;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _locationError =
            'Location services are turned off. Please enable them and try again.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationPermanentlyDenied = true;
          _locationError =
              'Location permission is permanently denied. Enable it from Settings to use this feature.';
        });
        return;
      }
      if (permission == LocationPermission.denied) {
        setState(() => _locationError =
            'Location permission denied. Please allow location access to use this feature.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      List<Placemark> placemarks;
      try {
        placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
      } catch (_) {
        setState(() => _locationError =
            "Couldn't determine your address from your location. Please enter it manually.");
        return;
      }
      if (placemarks.isEmpty) {
        setState(() => _locationError =
            "Couldn't determine your address from your location. Please enter it manually.");
        return;
      }

      final placemark = placemarks.first;
      final line1 = addressLine1FromPlacemark(placemark);

      setState(() {
        if (line1.isNotEmpty) _line1Controller.text = line1;
        if ((placemark.locality ?? '').isNotEmpty) {
          _cityController.text = placemark.locality!;
        }
        if ((placemark.administrativeArea ?? '').isNotEmpty) {
          _stateController.text = placemark.administrativeArea!;
        }
        if ((placemark.postalCode ?? '').isNotEmpty) {
          _pincodeController.text = placemark.postalCode!;
        }
        _addressLat = position.latitude;
        _addressLng = position.longitude;
        _line1Touched = true;
        _cityTouched = true;
        _stateTouched = true;
        _pincodeTouched = true;
      });
    } on TimeoutException {
      setState(() => _locationError =
          "Couldn't get your location in time. Please try again or enter it manually.");
    } catch (_) {
      setState(() => _locationError =
          'Something went wrong while detecting your location. Please enter it manually.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
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
              IconButtonCustom(icon: LucideIcons.arrowLeft, onPressed: _goBack),
              const SizedBox(height: AppSpacing.lg),
              const OnboardingProgressBar(currentStep: 1),
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
            Text('Could not load your address', style: AppTypography.body),
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
                    text: 'Your ',
                    style: TextStyle(color: AppColors.textPrimary)),
                TextSpan(
                  text: 'Address',
                  style: TextStyle(
                    foreground: Paint()
                      ..shader =
                          const LinearGradient(colors: AppColors.ctaGradient)
                              .createShader(const Rect.fromLTWH(0, 0, 120, 26)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Where you currently live',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: CurrentLocationTile(
              isLoading: _isLocating,
              onTap: _useCurrentLocation,
            ),
          ),
          if (_locationError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoBanner(
              icon: LucideIcons.alertTriangle,
              color: AppColors.warning,
              message: _locationError!,
              actionLabel: _locationPermanentlyDenied ? 'Open Settings' : null,
              onAction: _locationPermanentlyDenied
                  ? () => Geolocator.openAppSettings()
                  : null,
            ),
          ],
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
                  label: 'Address Line 1',
                  child: AppTextField(
                    label: 'Address Line 1',
                    controller: _line1Controller,
                    showFloatingLabel: false,
                    hint: 'House / flat / street',
                    readOnly: _sectionLocked,
                    errorText: _line1Touched && !_isLine1Valid
                        ? 'Address Line 1 is required'
                        : null,
                    prefixIcon: const Icon(LucideIcons.home,
                        color: AppColors.secondary, size: 20),
                    onChanged: (_) => setState(() => _line1Touched = true),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Address Line 2 (optional)',
                  child: AppTextField(
                    label: 'Address Line 2',
                    controller: _line2Controller,
                    showFloatingLabel: false,
                    hint: 'Apartment / suite / floor',
                    readOnly: _sectionLocked,
                    prefixIcon: const Icon(LucideIcons.building2,
                        color: AppColors.secondary, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Landmark (optional)',
                  child: AppTextField(
                    label: 'Landmark',
                    controller: _landmarkController,
                    showFloatingLabel: false,
                    hint: 'Nearby landmark',
                    readOnly: _sectionLocked,
                    prefixIcon: const Icon(LucideIcons.mapPin,
                        color: AppColors.secondary, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'City',
                  child: AppTextField(
                    label: 'City',
                    controller: _cityController,
                    showFloatingLabel: false,
                    hint: 'Enter your city',
                    readOnly: _sectionLocked,
                    errorText: _cityTouched && !_isCityValid
                        ? 'City is required'
                        : null,
                    prefixIcon: const Icon(LucideIcons.building,
                        color: AppColors.secondary, size: 20),
                    onChanged: (_) => setState(() => _cityTouched = true),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'State',
                  child: AppTextField(
                    label: 'State',
                    controller: _stateController,
                    showFloatingLabel: false,
                    hint: 'Enter your state',
                    readOnly: _sectionLocked,
                    errorText: _stateTouched && !_isStateValid
                        ? 'State is required'
                        : null,
                    prefixIcon: const Icon(LucideIcons.map,
                        color: AppColors.secondary, size: 20),
                    onChanged: (_) => setState(() => _stateTouched = true),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'PIN Code',
                  child: AppTextField(
                    label: 'PIN Code',
                    controller: _pincodeController,
                    showFloatingLabel: false,
                    hint: '6-digit PIN code',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    readOnly: _sectionLocked,
                    errorText: _pincodeTouched && !_isPincodeValid
                        ? 'Enter a valid 6-digit PIN code'
                        : null,
                    prefixIcon: const Icon(LucideIcons.hash,
                        color: AppColors.secondary, size: 20),
                    onChanged: (_) => setState(() => _pincodeTouched = true),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Country',
                  child: AppTextField(
                    label: 'Country',
                    controller: _countryController,
                    showFloatingLabel: false,
                    readOnly: true,
                    prefixIcon: const Icon(LucideIcons.flag,
                        color: AppColors.textSecondary, size: 20),
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
