import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../core/api/api_exception.dart';
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

    final name = widget.flow == AuthFlow.signUp
        ? ref.read(signupNameUiProvider).trim()
        : null;

    setState(() => _isVerifying = true);
    try {
      await ref.read(authSessionProvider.notifier).verifyOtp(phone, otp, name: name);
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
      if (widget.flow == AuthFlow.signUp) {
        Get.offNamed(AppRoutes.setPassword);
      } else {
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
            ],
          ),
        ),
      ),
    );
  }
}
