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
import '../../../providers/partner_registration/registration_form_provider.dart';
import '../../../repositories/partner_registration/partner_registration_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/step_progress_indicator.dart';
import '../widgets/labeled_field.dart';
import '../widgets/vehicle_type_display_field.dart';

class VehicleDetailsScreen extends ConsumerStatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  ConsumerState<VehicleDetailsScreen> createState() =>
      _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends ConsumerState<VehicleDetailsScreen> {
  final _vehicleNumberController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(registrationFormProvider);
    _vehicleNumberController.text = formState.vehicleNumber;
    _vehicleModelController.text = formState.vehicleModel;
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _vehicleModelController.dispose();
    super.dispose();
  }

  Future<void> _onContinue(RegistrationFormState formState) async {
    setState(() => _isSaving = true);
    await ref.read(partnerRegistrationRepositoryProvider).saveVehicle(
          VehicleModel(
            type: formState.vehicleType!,
            registrationNumber: formState.vehicleType == VehicleType.bicycle
                ? null
                : formState.vehicleNumber,
            model: formState.vehicleModel,
          ),
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    Get.toNamed(AppRoutes.deliveryZone);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(registrationFormProvider);
    final formNotifier = ref.read(registrationFormProvider.notifier);
    final vehicleType = formState.vehicleType;

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
                          totalSteps: 6, currentStep: 2),
                      const SizedBox(height: AppSpacing.lg),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.h1.copyWith(fontSize: 26),
                          children: [
                            const TextSpan(
                                text: 'Vehicle ',
                                style: TextStyle(color: AppColors.textPrimary)),
                            TextSpan(
                              text: 'Details',
                              style: TextStyle(
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                          colors: AppColors.ctaGradient)
                                      .createShader(
                                          const Rect.fromLTWH(0, 0, 120, 26)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Enter your vehicle information',
                        style: AppTypography.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
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
                            if (vehicleType != VehicleType.bicycle) ...[
                              LabeledField(
                                label: 'Vehicle Number',
                                child: AppTextField(
                                  label: 'Vehicle Number',
                                  controller: _vehicleNumberController,
                                  showFloatingLabel: false,
                                  hint: 'MH 01 AB 1234',
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  inputFormatters: [UpperCaseTextFormatter()],
                                  prefixIcon: const Icon(
                                    LucideIcons.creditCard,
                                    color: AppColors.secondary,
                                    size: 20,
                                  ),
                                  onChanged: formNotifier.setVehicleNumber,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            LabeledField(
                              label: 'Vehicle Type',
                              child: VehicleTypeDisplayField(
                                vehicleType: vehicleType!,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            LabeledField(
                              label: 'Vehicle Model',
                              child: AppTextField(
                                label: 'Vehicle Model',
                                controller: _vehicleModelController,
                                showFloatingLabel: false,
                                hint: 'e.g. Honda Shine',
                                prefixIcon: const Icon(
                                  LucideIcons.tag,
                                  color: AppColors.secondary,
                                  size: 20,
                                ),
                                onChanged: formNotifier.setVehicleModel,
                              ),
                            ),
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
                onPressed: formState.isVehicleDetailsValid
                    ? () => _onContinue(formState)
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
