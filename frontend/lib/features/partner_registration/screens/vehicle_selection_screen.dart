import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/partner_registration/vehicle_model.dart';
import '../../../providers/partner_registration/registration_form_provider.dart';
import '../../../repositories/partner_registration/partner_registration_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/step_progress_indicator.dart';
import '../widgets/vehicle_type_card.dart';

class VehicleSelectionScreen extends ConsumerStatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  ConsumerState<VehicleSelectionScreen> createState() =>
      _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState
    extends ConsumerState<VehicleSelectionScreen> {
  bool _isSaving = false;

  String _label(VehicleType type) => switch (type) {
        VehicleType.scooter => 'Bike Partner',
        VehicleType.bicycle => 'Cycle Partner',
        VehicleType.electricVehicle => 'E-Bike Partner',
        VehicleType.bike => 'Bike Partner',
      };

  String _image(VehicleType type) => switch (type) {
        VehicleType.scooter => 'assets/images/bike_3d.png',
        VehicleType.bicycle => 'assets/images/cycle_3d.png',
        VehicleType.electricVehicle => 'assets/images/e-bike_3d.png',
        VehicleType.bike => 'assets/images/bike_3d.png',
      };

  Future<void> _onContinue(VehicleType selected) async {
    setState(() => _isSaving = true);
    await ref
        .read(partnerRegistrationRepositoryProvider)
        .saveVehicle(VehicleModel(type: selected));
    if (!mounted) return;
    setState(() => _isSaving = false);
    Get.toNamed(AppRoutes.deliveryZone);
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(registrationFormProvider).vehicleType;
    final formNotifier = ref.read(registrationFormProvider.notifier);

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
                          totalSteps: 4, currentStep: 1),
                      const SizedBox(height: AppSpacing.lg),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.h1.copyWith(fontSize: 26),
                          children: [
                            const TextSpan(
                                text: 'Partner ',
                                style: TextStyle(color: AppColors.textPrimary)),
                            TextSpan(
                              text: 'Type',
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
                        'Choose how you want to deliver orders',
                        style: AppTypography.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      for (var i = 0; i < options.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.md),
                        VehicleTypeCard(
                          imageAsset: _image(options[i]),
                          label: _label(options[i]),
                          selected: selected == options[i],
                          isPopular: options[i] == VehicleType.scooter,
                          onTap: () => formNotifier.setVehicleType(options[i]),
                        ),
                      ],
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
                    selected != null ? () => _onContinue(selected) : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
