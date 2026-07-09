import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/partner_registration/personal_info_model.dart';
import '../../../providers/partner_registration/registration_form_provider.dart';
import '../../../repositories/partner_registration/partner_registration_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../widgets/date_of_birth_field.dart';
import '../widgets/gender_selector.dart';
import '../widgets/labeled_field.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyNumberController = TextEditingController();
  final _referralController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _emergencyNameController.dispose();
    _emergencyNumberController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _onContinue(RegistrationFormState formState) async {
    setState(() => _isSaving = true);
    final info = PersonalInfoModel(
      fullName: formState.fullName,
      dateOfBirth: formState.dateOfBirth!,
      gender: formState.gender!,
      email: formState.email.isEmpty ? null : formState.email,
      emergencyContactName: formState.emergencyContactName,
      emergencyContactNumber: formState.emergencyContactNumber,
      referralCode: formState.referralCode.isEmpty ? null : formState.referralCode,
    );
    await ref.read(partnerRegistrationRepositoryProvider).savePersonalInfo(info);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Get.toNamed(AppRoutes.vehicleSelection);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(registrationFormProvider);
    final formNotifier = ref.read(registrationFormProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              IconButtonCustom(icon: LucideIcons.arrowLeft, onPressed: () => Get.back()),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppTypography.h1.copyWith(fontSize: 26),
                          children: [
                            const TextSpan(text: 'Tell us ', style: TextStyle(color: AppColors.textPrimary)),
                            TextSpan(
                              text: 'about yourself',
                              style: TextStyle(
                                foreground: Paint()
                                  ..shader = const LinearGradient(colors: AppColors.ctaGradient)
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
                      LabeledField(
                        label: 'Full Name',
                        child: AppTextField(
                          label: 'Full Name',
                          controller: _fullNameController,
                          showFloatingLabel: false,
                          hint: 'Enter your full name',
                          prefixIcon: const Icon(LucideIcons.user, color: AppColors.secondary, size: 20),
                          onChanged: formNotifier.setFullName,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: 'Email ID',
                        child: AppTextField(
                          label: 'Email ID',
                          controller: _emailController,
                          showFloatingLabel: false,
                          hint: 'you@email.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(LucideIcons.mail, color: AppColors.secondary, size: 20),
                          onChanged: formNotifier.setEmail,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: 'Date of Birth',
                        child: DateOfBirthField(
                          value: formState.dateOfBirth,
                          onChanged: formNotifier.setDateOfBirth,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: 'Gender',
                        child: GenderSelector(
                          selected: formState.gender,
                          onChanged: formNotifier.setGender,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: 'Emergency Contact Name (with relation)',
                        child: AppTextField(
                          label: 'Emergency Contact Name',
                          controller: _emergencyNameController,
                          showFloatingLabel: false,
                          hint: 'e.g. Suresh Verma (Father)',
                          prefixIcon: const Icon(LucideIcons.users, color: AppColors.secondary, size: 20),
                          onChanged: formNotifier.setEmergencyContactName,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: 'Emergency Contact Number',
                        child: AppTextField(
                          label: 'Emergency Contact Number',
                          controller: _emergencyNumberController,
                          showFloatingLabel: false,
                          hint: '10-digit mobile number',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(LucideIcons.phone, color: AppColors.secondary, size: 20),
                          onChanged: formNotifier.setEmergencyContactNumber,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: 'Referral Code (optional)',
                        child: AppTextField(
                          label: 'Referral Code',
                          controller: _referralController,
                          showFloatingLabel: false,
                          hint: 'Enter referral code',
                          prefixIcon: const Icon(LucideIcons.gift, color: AppColors.secondary, size: 20),
                          onChanged: formNotifier.setReferralCode,
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
                onPressed: formState.isPersonalInfoValid ? () => _onContinue(formState) : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
