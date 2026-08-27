import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/branding/qikzoo_partner_logo.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/authentication/auth_flow.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../repositories/authentication/auth_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/inputs/otp_field.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/countdown_timer.dart';
import '../../../repositories/profile/profile_repository.dart';
import '../../../repositories/onboarding_status/onboarding_status_repository.dart';
import '../../../core/navigation/next_onboarding_step_resolver.dart';
import '../../../core/referrals/referral_attribution_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../repositories/referrals/referral_repository.dart';

const _qikzooNavy = Color(0xFF162B4D);

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    super.key,
    this.flow = AuthFlow.login,
  });

  final AuthFlow flow;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with CodeAutoFill {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _canResend = false;
  int _resendAttempt = 0;

  String get _phone => ref.read(phoneNumberUiProvider).trim().isNotEmpty
      ? ref.read(phoneNumberUiProvider).trim()
      : (Get.parameters['phone'] ?? '').trim();

  @override
  void initState() {
    super.initState();
    _startOtpListener();
  }

  @override
  void dispose() {
    cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  void codeUpdated() {
    final receivedCode = code;
    if (receivedCode == null || receivedCode.isEmpty || !mounted) return;
    _applyAutofilledCode(receivedCode);
  }

  void _startOtpListener() {
    listenForCode(smsCodeRegexPattern: '\\d{${AppConstants.otpLength}}');
  }

  void _applyAutofilledCode(String receivedCode) {
    final digitsOnly = receivedCode.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < AppConstants.otpLength) return;

    final otp = digitsOnly.substring(0, AppConstants.otpLength);
    _otpController
      ..text = otp
      ..selection = TextSelection.collapsed(offset: otp.length);

    _onOtpCompleted(otp);
  }

  Future<void> _onOtpCompleted(String otp) async {
    if (_isVerifying) return;

    final phone = _phone;
    if (phone.isEmpty) {
      AppSnackBar.error(
        context,
        'Phone number missing. Please request the OTP again.',
      );
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final name = widget.flow == AuthFlow.signUp
          ? ref.read(signupNameUiProvider).trim()
          : null;
      await ref
          .read(authSessionProvider.notifier)
          .verifyOtp(phone, otp, name: name);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      AppSnackBar.error(context, 'Could not verify the OTP. Please try again.');
      return;
    }

    if (!mounted) return;
    setState(() => _isVerifying = false);
    final authState = ref.read(authSessionProvider);
    if (authState.hasError) {
      final error = authState.error;
      AppSnackBar.error(
        context,
        error is ApiException
            ? error.message
            : 'Could not verify the OTP. Please try again.',
      );
      return;
    }

    final session = authState.value;
    if (session?.isAuthenticated == true) {
      setState(() => _isVerifying = true);
      try {
        if (session!.isNewRider) {
          final attribution = ReferralAttributionService(SecureTokenStorage());
          final code = await attribution.pendingCode();
          if (code != null) {
            await ref.read(referralRepositoryProvider).applyCode(code);
            await attribution.clear();
          }
        }
        final profile = await ref.read(profileRepositoryProvider).getProfile();
        final onboarding =
            await ref.read(onboardingStatusRepositoryProvider).getStatus();
        final nextRoute =
            NextOnboardingStepResolver.resolve(onboarding, profile: profile);
        Get.offAllNamed(nextRoute);
      } catch (_) {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    }
  }

  Future<void> _onResend() async {
    final phone = _phone;
    if (phone.isEmpty) {
      AppSnackBar.error(
        context,
        'Phone number missing. Please request the OTP again.',
      );
      return;
    }

    try {
      await ref.read(authRepositoryProvider).requestOtp(phone);
    } catch (error) {
      if (mounted) {
        AppSnackBar.error(
          context,
          error is ApiException
              ? error.message
              : 'Could not resend the OTP. Please try again.',
        );
      }
      return;
    }
    if (!mounted) return;
    _otpController.clear();
    setState(() {
      _canResend = false;
      _resendAttempt++;
    });
    _startOtpListener();
  }

  String _maskedPhone(String phone) {
    if (phone.length != 10) return '+91 XXXXX XXXXX';
    return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(phoneNumberUiProvider);
    final displayPhone = phone.trim().isNotEmpty
        ? phone.trim()
        : (Get.parameters['phone'] ?? '').trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _OtpTopBar(),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.5)),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'VERIFY YOUR NUMBER',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Verify OTP',
                              style: AppTypography.h1.copyWith(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: _qikzooNavy,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter the ${AppConstants.otpLength} digit OTP sent to',
                              style: AppTypography.body
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              _maskedPhone(displayPhone),
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            IgnorePointer(
                              ignoring: _isVerifying,
                              child: Opacity(
                                opacity: _isVerifying ? 0.5 : 1,
                                child: AutofillGroup(
                                  child: OtpField(
                                    length: AppConstants.otpLength,
                                    controller: _otpController,
                                    autoFocus: true,
                                    onCompleted: _onOtpCompleted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Center(
                              child: _canResend
                                  ? GestureDetector(
                                      onTap: _onResend,
                                      child: Text(
                                        'Resend OTP',
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Resend OTP in  ',
                                            style: AppTypography.body.copyWith(
                                                color:
                                                    AppColors.textSecondary)),
                                        CountdownTimer(
                                          key: ValueKey(_resendAttempt),
                                          seconds: 30,
                                          color: AppColors.accent,
                                          onExpired: () =>
                                              setState(() => _canResend = true),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
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

/// Back button + a "2/2" step badge Ã¢â‚¬â€ the same widget shape used for the
/// login flow's first step and for onboarding's welcome/benefits pair.
class _OtpTopBar extends StatelessWidget {
  const _OtpTopBar();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButtonCustom(
              icon: LucideIcons.arrowLeft,
              tooltip: 'Back',
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Get.offAllNamed(AppRoutes.mobileNumber);
                }
              },
            ),
            const Spacer(),
            const QikzooPartnerLogo(width: 150),
            const Spacer(),
            const _StepBadge(current: 2, total: 2),
          ],
        ),
      );
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= total; i++) ...[
              if (i > 1) const SizedBox(width: 4),
              Container(
                width: i == current ? 14 : 4,
                height: 4,
                decoration: BoxDecoration(
                  color: i <= current ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Text(
              '$current/$total',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}
