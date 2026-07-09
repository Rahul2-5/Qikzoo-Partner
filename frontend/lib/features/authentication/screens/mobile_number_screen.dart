import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/validators/validators.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../repositories/authentication/auth_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../widgets/mobile_hero_illustration.dart';
import '../widgets/phone_input_field.dart';

class MobileNumberScreen extends ConsumerStatefulWidget {
  const MobileNumberScreen({super.key});

  @override
  ConsumerState<MobileNumberScreen> createState() => _MobileNumberScreenState();
}

class _MobileNumberScreenState extends ConsumerState<MobileNumberScreen> {
  final _controller = TextEditingController();
  bool _isRequesting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onContinue(String phone) async {
    setState(() => _isRequesting = true);
    await ref.read(authRepositoryProvider).requestOtp(phone);
    if (!mounted) return;
    setState(() => _isRequesting = false);
    Get.toNamed(AppRoutes.otpVerification);
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(phoneNumberUiProvider);
    final isValid = Validators.isValidPhone(phone);

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: AppTypography.h1.copyWith(fontSize: 28, height: 1.25),
                            children: const [
                              TextSpan(text: 'Enter ', style: TextStyle(color: AppColors.textPrimary)),
                              TextSpan(text: 'Mobile', style: TextStyle(color: AppColors.secondary)),
                              TextSpan(text: '\nNumber', style: TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          "We'll send you an OTP to verify your number",
                          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const MobileHeroIllustration(),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              PhoneInputField(
                controller: _controller,
                onChanged: (value) => ref.read(phoneNumberUiProvider.notifier).state = value,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryCtaButton(
                label: 'Continue',
                trailingIcon: LucideIcons.arrowRight,
                isLoading: _isRequesting,
                onPressed: isValid ? () => _onContinue(phone) : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.15))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text('or continue with',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.15))),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    children: const [
                      TextSpan(text: 'By continuing, you agree to our\n'),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
