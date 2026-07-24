import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/partner_registration/vehicle_model.dart';
import '../../../providers/partner_registration/vehicle_details_provider.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../profile/widgets/account_screen_components.dart';

class ManageVehicleDetailsScreen extends ConsumerStatefulWidget {
  const ManageVehicleDetailsScreen({super.key});

  @override
  ConsumerState<ManageVehicleDetailsScreen> createState() =>
      _ManageVehicleDetailsScreenState();
}

class _ManageVehicleDetailsScreenState
    extends ConsumerState<ManageVehicleDetailsScreen> {
  final _registrationController = TextEditingController();
  final _modelController = TextEditingController();
  VehicleType _selectedType = VehicleType.scooter;
  bool _didPopulate = false;
  String? _registrationError;
  String? _modelError;

  static final _registrationPattern =
      RegExp(r'^[A-Z]{2}\s?\d{1,2}\s?[A-Z]{1,2}\s?\d{4}$');

  @override
  void dispose() {
    _registrationController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _populate(VehicleModel? vehicle) {
    if (_didPopulate) return;
    _didPopulate = true;
    if (vehicle == null) return;
    _selectedType = vehicle.type;
    _registrationController.text = vehicle.registrationNumber ?? '';
    _modelController.text = vehicle.model ?? '';
  }

  bool _validate() {
    final registration = _registrationController.text.trim().toUpperCase();
    final model = _modelController.text.trim();
    setState(() {
      _registrationError = _selectedType != VehicleType.bicycle &&
              !_registrationPattern.hasMatch(registration)
          ? 'Enter a valid vehicle number'
          : null;
      _modelError = model.length < 2 ? 'Enter your vehicle model' : null;
    });
    return _registrationError == null && _modelError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    await ref.read(vehicleDetailsProvider.notifier).save(
          VehicleModel(
            type: _selectedType,
            registrationNumber: _selectedType == VehicleType.bicycle
                ? null
                : _registrationController.text.trim().toUpperCase(),
            model: _modelController.text.trim(),
          ),
        );
    if (!mounted) return;
    if (ref.read(vehicleDetailsProvider).hasError) {
      AppSnackBar.error(context, 'Could not update vehicle details.');
    } else {
      AppSnackBar.success(context, 'Vehicle details updated');
    }
  }

  String _typeLabel(VehicleType type) => switch (type) {
        VehicleType.scooter => 'Bike / scooter',
        VehicleType.bicycle => 'Bicycle',
        VehicleType.electricVehicle => 'Electric bike',
        VehicleType.bike => 'Motorbike',
      };

  @override
  Widget build(BuildContext context) {
    final vehicleAsync = ref.watch(vehicleDetailsProvider);
    if (vehicleAsync.hasValue) _populate(vehicleAsync.valueOrNull);
    final showInitialLoader = vehicleAsync.isLoading && !_didPopulate;
    const options = [
      VehicleType.scooter,
      VehicleType.bicycle,
      VehicleType.electricVehicle,
    ];

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
                subtitle:
                    'Keep your active delivery vehicle information up to date.',
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: showInitialLoader
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            AccountSectionCard(
                              title: 'Vehicle type',
                              child: Column(
                                children: [
                                  for (var index = 0;
                                      index < options.length;
                                      index++) ...[
                                    if (index > 0)
                                      const SizedBox(height: AppSpacing.sm),
                                    _VehicleTypeOption(
                                      type: options[index],
                                      label: _typeLabel(options[index]),
                                      selected: _selectedType == options[index],
                                      onTap: () => setState(() {
                                        _selectedType = options[index];
                                        _registrationError = null;
                                      }),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AccountSectionCard(
                              title: 'Vehicle information',
                              child: Column(
                                children: [
                                  if (_selectedType != VehicleType.bicycle) ...[
                                    AppTextField(
                                      label: 'Registration number',
                                      hint: 'e.g. MH 01 AB 1234',
                                      controller: _registrationController,
                                      errorText: _registrationError,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      inputFormatters: [
                                        _UpperCaseTextFormatter(),
                                        FilteringTextInputFormatter.allow(
                                          RegExp('[A-Z0-9 ]'),
                                        ),
                                      ],
                                      prefixIcon: const Icon(
                                        LucideIcons.creditCard,
                                        color: AppColors.secondary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                  AppTextField(
                                    label: 'Vehicle model',
                                    hint: _selectedType == VehicleType.bicycle
                                        ? 'e.g. Hero Sprint'
                                        : 'e.g. Honda Activa 6G',
                                    controller: _modelController,
                                    errorText: _modelError,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    prefixIcon: const Icon(
                                      LucideIcons.tag,
                                      color: AppColors.secondary,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const AccountInfoBanner(
                              icon: LucideIcons.fileCheck2,
                              title: 'Vehicle documents',
                              message:
                                  'Registration and insurance documents can be managed separately.',
                              color: AppColors.primary,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () =>
                                    Get.toNamed(AppRoutes.manageDocuments),
                                icon:
                                    const Icon(LucideIcons.fileText, size: 18),
                                label: const Text('Manage documents'),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
              ),
              PrimaryCtaButton(
                label: 'Save vehicle details',
                trailingIcon: LucideIcons.check,
                isLoading: vehicleAsync.isLoading && _didPopulate,
                onPressed: vehicleAsync.isLoading ? null : _save,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleTypeOption extends StatelessWidget {
  final VehicleType type;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleTypeOption({
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.secondaryBg : AppColors.background,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Image.asset(type.imageAsset, width: 42, height: 42),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: AppTypography.bodyMedium)),
              Icon(
                selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                color: selected ? AppColors.secondary : AppColors.textSecondary,
                size: 21,
              ),
            ],
          ),
        ),
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
