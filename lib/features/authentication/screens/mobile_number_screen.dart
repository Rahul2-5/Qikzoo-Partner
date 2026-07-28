import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/validators/validators.dart';
import '../../../models/authentication/auth_flow.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../repositories/authentication/auth_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';
import '../widgets/phone_input_field.dart';

class MobileNumberScreen extends ConsumerStatefulWidget {
  const MobileNumberScreen({
    super.key,
    this.flow = AuthFlow.login,
  });

  final AuthFlow flow;

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
    if (_isRequesting) return;
    if (!Validators.isValidPhone(phone)) {
      AppSnackBar.warning(context, 'Please enter a valid mobile number.');
      return;
    }

    setState(() => _isRequesting = true);
    try {
      await ref.read(authRepositoryProvider).requestOtp(phone);
      if (!mounted) return;
      Get.toNamed(
        authFlowRoute(
          AppRoutes.otpVerification,
          widget.flow,
          phone: phone,
        ),
      );
    } catch (error) {
      if (mounted) {
        AppSnackBar.error(
          context,
          error is ApiException
              ? error.message
              : 'Could not send the OTP. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(phoneNumberUiProvider);
    final isPhoneValid = Validators.isValidPhone(phone);
    final canAttemptContinue = phone.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 480,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              AppStaggeredReveal(
                index: 0,
                child: IconButtonCustom(
                  icon: LucideIcons.arrowLeft,
                  onPressed: Get.back,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      const AppStaggeredReveal(index: 1, child: _MobileHero()),
                      const SizedBox(height: AppSpacing.xxl),
                      AppStaggeredReveal(
                        index: 2,
                        child: PhoneInputField(
                          controller: _controller,
                          isValid: isPhoneValid,
                          onChanged: (value) => ref
                              .read(phoneNumberUiProvider.notifier)
                              .state = value,
                          onSubmitted: canAttemptContinue && !_isRequesting
                              ? (_) => _onContinue(phone)
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        isPhoneValid
                            ? 'Number looks good'
                            : 'Enter a valid 10 digit mobile number',
                        style: AppTypography.body.copyWith(
                          color: isPhoneValid
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.body
                              .copyWith(color: AppColors.textSecondary),
                          children: const [
                            TextSpan(text: 'Lost your phone number? '),
                            TextSpan(
                              text: 'Reach us',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppStaggeredReveal(
                        index: 3,
                        child: PrimaryCtaButton(
                          label: 'Continue',
                          trailingIcon: LucideIcons.arrowRight,
                          isLoading: _isRequesting,
                          onPressed: canAttemptContinue
                              ? () => _onContinue(phone)
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
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
                        TextSpan(text: 'By continuing, you agree to our '),
                        TextSpan(
                          text: 'Terms and Conditions',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
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

class _MobileHero extends StatelessWidget {
  const _MobileHero();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Image.asset(
            AppAssets.mainLogo,
            width: 220,
            height: 116,
            fit: BoxFit.contain,
            semanticLabel: 'Qikzoo Delivery Partner',
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Sign in to your account',
            textAlign: TextAlign.center,
            style: AppTypography.h1.copyWith(fontSize: 29),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Login or create an account',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      );
}

@Preview(
    name: 'Mobile number entry', group: 'Authentication', size: Size(390, 844))
Widget mobileNumberScreenPreview() => ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MobileNumberScreen(),
      ),
    );
