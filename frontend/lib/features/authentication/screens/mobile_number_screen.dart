import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
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
import '../widgets/mobile_hero_illustration.dart';
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
    final isValid = Validators.isValidPhone(phone);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF1FF), AppColors.background],
            stops: [0, 0.42],
          ),
        ),
        child: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 480,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                AppStaggeredReveal(
                  index: 0,
                  child: Row(
                    children: [
                      IconButtonCustom(
                        icon: LucideIcons.arrowLeft,
                        onPressed: () => Get.back(),
                      ),
                      const Spacer(),
                      _StepBadge(flow: widget.flow),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final showHero = constraints.maxWidth >= 340;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppStaggeredReveal(
                              index: 1,
                              child: _MobileHero(showIllustration: showHero),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppStaggeredReveal(
                              index: 2,
                              child: Text(
                                'Mobile number',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppStaggeredReveal(
                              index: 3,
                              child: PhoneInputField(
                                controller: _controller,
                                isValid: isValid,
                                onChanged: (value) => ref
                                    .read(phoneNumberUiProvider.notifier)
                                    .state = value,
                                onSubmitted: isValid && !_isRequesting
                                    ? (_) => _onContinue(phone)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Icon(
                                  isValid
                                      ? LucideIcons.checkCircle2
                                      : LucideIcons.info,
                                  size: 15,
                                  color: isValid
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    isValid
                                        ? 'Number looks good'
                                        : 'Enter a valid 10-digit Indian number',
                                    style: AppTypography.caption.copyWith(
                                      color: isValid
                                          ? AppColors.success
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppStaggeredReveal(
                              index: 3,
                              child: PrimaryCtaButton(
                                label: 'Continue',
                                trailingIcon: LucideIcons.arrowRight,
                                isLoading: _isRequesting,
                                onPressed:
                                    isValid ? () => _onContinue(phone) : null,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const AppStaggeredReveal(
                              index: 4,
                              child: _SecurityNote(),
                            ),
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
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.flow});

  final AuthFlow flow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        flow == AuthFlow.signUp ? 'Partner signup' : 'Secure login',
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero({required this.showIllustration});

  final bool showIllustration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F3F51B5),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBg,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    'SECURE SIGN IN',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                RichText(
                  text: TextSpan(
                    style: AppTypography.display.copyWith(fontSize: 27),
                    children: const [
                      TextSpan(text: 'Enter your\n'),
                      TextSpan(
                        text: 'mobile number',
                        style: TextStyle(color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "We'll send a one-time password to verify it's you.",
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (showIllustration) ...[
            const SizedBox(width: AppSpacing.md),
            const MobileHeroIllustration(width: 92, height: 148),
          ],
        ],
      ),
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

@Preview(
    name: 'Mobile number entry', group: 'Authentication', size: Size(390, 844))
Widget mobileNumberScreenPreview() {
  return ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MobileNumberScreen(),
    ),
  );
}
