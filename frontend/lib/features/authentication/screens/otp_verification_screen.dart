import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/authentication/auth_flow.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../repositories/authentication/auth_repository.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/inputs/numeric_keypad.dart';
import '../../../shared/widgets/inputs/otp_field.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/countdown_timer.dart';

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

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _canResend = false;
  int _resendAttempt = 0;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onDigitTap(String digit) {
    if (_otpController.text.length >= AppConstants.otpLength) return;
    _otpController.text += digit;
  }

  void _onBackspaceTap() {
    if (_otpController.text.isEmpty) return;
    _otpController.text =
        _otpController.text.substring(0, _otpController.text.length - 1);
  }

  Future<void> _onOtpCompleted(String otp) async {
    final phone = ref.read(phoneNumberUiProvider);
    setState(() => _isVerifying = true);
    await ref.read(authSessionProvider.notifier).verifyOtp(phone, otp);
    if (!mounted) return;
    setState(() => _isVerifying = false);
    final session = ref.read(authSessionProvider).value;
    if (session?.isAuthenticated == true) {
      if (widget.flow == AuthFlow.signUp) {
        Get.offNamed(AppRoutes.setPassword);
      } else {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    }
  }

  Future<void> _onResend() async {
    final phone = ref.read(phoneNumberUiProvider);
    await ref.read(authRepositoryProvider).requestOtp(phone);
    if (!mounted) return;
    _otpController.clear();
    setState(() {
      _canResend = false;
      _resendAttempt++;
    });
  }

  String _maskedPhone(String phone) {
    if (phone.length != 10) return '+91 XXXXX XXXXX';
    return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(phoneNumberUiProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      IconButtonCustom(
                          icon: LucideIcons.arrowLeft,
                          onPressed: () => Get.back()),
                      const SizedBox(height: AppSpacing.lg),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.h1.copyWith(fontSize: 28),
                          children: [
                            const TextSpan(
                                text: 'Verify ',
                                style: TextStyle(color: AppColors.textPrimary)),
                            TextSpan(
                              text: 'OTP',
                              style: TextStyle(
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                          colors: AppColors.ctaGradient)
                                      .createShader(
                                          const Rect.fromLTWH(0, 0, 90, 28)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Enter the ${AppConstants.otpLength} digit OTP sent to',
                        style: AppTypography.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        _maskedPhone(phone),
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      IgnorePointer(
                        ignoring: _isVerifying,
                        child: Opacity(
                          opacity: _isVerifying ? 0.5 : 1,
                          child: OtpField(
                            length: AppConstants.otpLength,
                            controller: _otpController,
                            readOnly: true,
                            onCompleted: _onOtpCompleted,
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
                                  style: AppTypography.bodyMedium.copyWith(
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
                                          color: AppColors.textSecondary)),
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
              ),
              IgnorePointer(
                ignoring: _isVerifying,
                child: NumericKeypad(
                    onDigitTap: _onDigitTap, onBackspaceTap: _onBackspaceTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
