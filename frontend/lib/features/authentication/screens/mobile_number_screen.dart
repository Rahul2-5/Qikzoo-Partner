import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/validators/validators.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../repositories/authentication/auth_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
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
        child: ResponsiveFrame(
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final showHero = constraints.maxWidth >= 360;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHero)
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _MobileHeader()),
                                SizedBox(width: AppSpacing.md),
                                MobileHeroIllustration(),
                              ],
                            )
                          else
                            const _MobileHeader(),
                          const SizedBox(height: AppSpacing.xl),
                          PhoneInputField(
                            controller: _controller,
                            onChanged: (value) => ref
                                .read(phoneNumberUiProvider.notifier)
                                .state = value,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryCtaButton(
                            label: 'Continue',
                            trailingIcon: LucideIcons.arrowRight,
                            isLoading: _isRequesting,
                            onPressed:
                                isValid ? () => _onContinue(phone) : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _SecurityNote(),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary),
                      children: const [
                        TextSpan(text: 'By continuing, you agree to our\n'),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
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

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTypography.display.copyWith(fontSize: 28),
            children: const [
              TextSpan(
                  text: 'Enter ',
                  style: TextStyle(color: AppColors.textPrimary)),
              TextSpan(
                  text: 'Mobile', style: TextStyle(color: AppColors.secondary)),
              TextSpan(
                  text: '\nNumber',
                  style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          "We'll send you an OTP to verify your number",
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondaryBg,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: const Icon(LucideIcons.shieldCheck,
                color: AppColors.secondary, size: 19),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Your number is used only for secure OTP verification.',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
