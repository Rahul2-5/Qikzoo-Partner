import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/city_data.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/partner_registration/delivery_zone_model.dart';
import '../../../providers/partner_registration/registration_form_provider.dart';
import '../../../repositories/partner_registration/partner_registration_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/inputs/search_bar_custom.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/navigation/step_progress_indicator.dart';
import '../widgets/city_list_tile.dart';
import '../widgets/current_location_tile.dart';

class SelectCityScreen extends ConsumerStatefulWidget {
  const SelectCityScreen({super.key});

  @override
  ConsumerState<SelectCityScreen> createState() => _SelectCityScreenState();
}

class _SelectCityScreenState extends ConsumerState<SelectCityScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCity;
  bool _isLocating = false;
  String? _locationError;
  bool _isSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CityInfo> get _filteredCities {
    if (_query.trim().isEmpty) return CityData.popularCities;
    final normalized = _query.trim().toLowerCase();
    return CityData.popularCities
        .where((city) => city.name.toLowerCase().contains(normalized))
        .toList();
  }

  Future<void> _onCurrentLocationTap() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _locationError =
            'Location services are turned off — please pick your city manually.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationError =
            'Location permission denied — please pick your city manually.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (placemarks.isEmpty) {
        setState(() => _locationError =
            'Couldn\'t detect your city — please pick it manually.');
        return;
      }

      final placemark = placemarks.first;
      final match = CityData.findByName(placemark.locality ?? '') ??
          CityData.findByName(placemark.subAdministrativeArea ?? '');

      if (match == null) {
        final detected = placemark.locality?.isNotEmpty == true
            ? placemark.locality!
            : 'your area';
        setState(() => _locationError =
            'We\'re not available in $detected yet — pick from the list below.');
        return;
      }

      setState(() => _selectedCity = match.name);
    } catch (_) {
      setState(() => _locationError =
          'Couldn\'t detect your location — please pick your city manually.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _onContinue() async {
    final city = CityData.findByName(_selectedCity ?? '');
    if (city == null) return;

    setState(() => _isSaving = true);
    ref.read(registrationFormProvider.notifier).setZone(city.state, city.name);
    await ref.read(partnerRegistrationRepositoryProvider).saveDeliveryZone(
          DeliveryZoneModel(
            state: city.state,
            city: city.name,
            preferredZone: '',
          ),
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    Get.toNamed(AppRoutes.documentUpload);
  }

  @override
  Widget build(BuildContext context) {
    final cities = _filteredCities;

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
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepProgressIndicator(
                          totalSteps: 4, currentStep: 2),
                      const SizedBox(height: AppSpacing.lg),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.h1.copyWith(fontSize: 26),
                          children: [
                            const TextSpan(
                                text: 'Select your ',
                                style: TextStyle(color: AppColors.textPrimary)),
                            TextSpan(
                              text: 'City',
                              style: TextStyle(
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                          colors: AppColors.ctaGradient)
                                      .createShader(
                                          const Rect.fromLTWH(0, 0, 80, 26)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Choose the city you want to deliver in',
                        style: AppTypography.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SearchBarCustom(
                        controller: _searchController,
                        hint: 'Search city',
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_locationError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.control),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.alertCircle,
                                  color: AppColors.warning, size: 18),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  _locationError!,
                                  style: AppTypography.caption
                                      .copyWith(color: AppColors.warning),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _locationError = null),
                                child: const Icon(LucideIcons.x,
                                    color: AppColors.warning, size: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            CurrentLocationTile(
                              isLoading: _isLocating,
                              onTap: _onCurrentLocationTap,
                            ),
                            const CityListDivider(),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs),
                                child: Text(
                                  'Popular Cities',
                                  style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                            if (cities.isEmpty)
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                child: EmptyState(
                                  icon: LucideIcons.searchX,
                                  message: 'No cities found',
                                ),
                              )
                            else
                              for (var i = 0; i < cities.length; i++) ...[
                                if (i > 0) const CityListDivider(),
                                CityListTile(
                                  name: cities[i].name,
                                  selected: _selectedCity == cities[i].name,
                                  onTap: () => setState(
                                      () => _selectedCity = cities[i].name),
                                ),
                              ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              PrimaryCtaButton(
                label: 'Continue',
                trailingIcon: LucideIcons.arrowRight,
                isLoading: _isSaving,
                onPressed:
                    _selectedCity != null ? _onContinue : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
