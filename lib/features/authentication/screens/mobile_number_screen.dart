import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validators/validators.dart';
import '../../../models/authentication/auth_flow.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../repositories/authentication/auth_repository.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../widgets/mobile_number_layout.dart';

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
  late final TextEditingController _controller;
  late final TextEditingController _nameController;
  bool _isRequesting = false;
  bool _nameTouched = false;

  bool get _isNameValid => Validators.isValidFullName(_nameController.text);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(phoneNumberUiProvider),
    );
    _nameController = TextEditingController(
      text: ref.read(signupNameUiProvider),
    );
    _nameController.addListener(() {
      ref.read(signupNameUiProvider.notifier).state = _nameController.text;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onContinue(String phone) async {
    if (_isRequesting) return;
    if (!Validators.isValidPhone(phone)) {
      AppSnackBar.warning(context, 'Please enter a valid mobile number.');
      return;
    }

    // The backend requires a name to create a brand-new rider account on
    // the verify-otp call (see RiderAuthService.verifyOtpLogin) — collect
    // it here, before the OTP is even sent, rather than on the next screen.
    if (widget.flow == AuthFlow.signUp && !_isNameValid) {
      setState(() => _nameTouched = true);
      AppSnackBar.warning(context, 'Please enter your full name.');
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

  void _onBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Get.offAllNamed(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(phoneNumberUiProvider);
    final isPhoneValid = Validators.isValidPhone(phone);
    final canAttemptContinue = phone.isNotEmpty;

    return MobileNumberLayout(
      flow: widget.flow,
      controller: _controller,
      phone: phone,
      isPhoneValid: isPhoneValid,
      isRequesting: _isRequesting,
      onBack: _onBack,
      onPhoneChanged: (value) =>
          ref.read(phoneNumberUiProvider.notifier).state = value,
      onSubmitted: canAttemptContinue && !_isRequesting
          ? (_) => _onContinue(phone)
          : null,
      onContinue: canAttemptContinue ? () => _onContinue(phone) : null,
      nameController: _nameController,
      nameErrorText: _nameTouched && !_isNameValid
          ? 'Enter 2-60 characters, no emoji'
          : null,
      onNameChanged: (_) => setState(() => _nameTouched = true),
    );
  }
}

@Preview(
  name: 'Compact phone',
  group: 'Authentication - Light',
  size: Size(320, 568),
)
@Preview(
  name: 'Standard phone',
  group: 'Authentication - Light',
  size: Size(390, 844),
)
@Preview(
  name: 'Phone landscape',
  group: 'Authentication - Light',
  size: Size(844, 390),
)
@Preview(
  name: 'Tablet',
  group: 'Authentication - Light',
  size: Size(1024, 768),
)
Widget mobileNumberScreenPreview() => ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        home: const MobileNumberScreen(),
      ),
    );
