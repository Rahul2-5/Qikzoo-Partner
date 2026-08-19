import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/authentication/auth_flow.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/branding/qikzoo_partner_logo.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';
import 'phone_input_field.dart';

class MobileNumberLayout extends StatelessWidget {
  const MobileNumberLayout({
    super.key,
    required this.flow,
    required this.controller,
    required this.phone,
    required this.isPhoneValid,
    required this.isRequesting,
    required this.onBack,
    required this.onPhoneChanged,
    required this.onContinue,
    this.onSubmitted,
  });

  final AuthFlow flow;
  final TextEditingController controller;
  final String phone;
  final bool isPhoneValid;
  final bool isRequesting;
  final VoidCallback onBack;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback? onContinue;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ResponsiveFrame(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale =
                    MediaQuery.textScalerOf(context).scale(1).clamp(1, 3);
                final isCompact = constraints.maxWidth < 360 ||
                    constraints.maxHeight < 700 ||
                    textScale > 1.3;
                const horizontalPadding = AppSpacing.sm;
                final verticalPadding =
                    isCompact ? AppSpacing.sm : AppSpacing.md;

                return FocusTraversalGroup(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          verticalPadding,
                          horizontalPadding,
                          0,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: _LoginHeader(onBack: onBack),
                        ),
                      ),
                      Expanded(
                        child: CustomScrollView(
                          key: const ValueKey('mobile-number-scroll-view'),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                isCompact ? AppSpacing.sm : AppSpacing.md,
                                horizontalPadding,
                                verticalPadding,
                              ),
                              sliver: SliverFillRemaining(
                                hasScrollBody: false,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 480),
                                    child: _NarrowLoginLayout(
                                      flow: flow,
                                      controller: controller,
                                      phone: phone,
                                      isPhoneValid: isPhoneValid,
                                      isRequesting: isRequesting,
                                      isCompact: isCompact,
                                      onPhoneChanged: onPhoneChanged,
                                      onContinue: onContinue,
                                      onSubmitted: onSubmitted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NarrowLoginLayout extends StatelessWidget {
  const _NarrowLoginLayout({
    required this.flow,
    required this.controller,
    required this.phone,
    required this.isPhoneValid,
    required this.isRequesting,
    required this.isCompact,
    required this.onPhoneChanged,
    required this.onContinue,
    required this.onSubmitted,
  });

  final AuthFlow flow;
  final TextEditingController controller;
  final String phone;
  final bool isPhoneValid;
  final bool isRequesting;
  final bool isCompact;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback? onContinue;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppStaggeredReveal(
          index: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _LoginFormCard(
              flow: flow,
              controller: controller,
              phone: phone,
              isPhoneValid: isPhoneValid,
              isRequesting: isRequesting,
              isCompact: isCompact,
              onPhoneChanged: onPhoneChanged,
              onContinue: onContinue,
              onSubmitted: onSubmitted,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppStaggeredReveal(index: 2, child: _LegalNotice()),
      ],
    );
  }
}

/// Entry point of the auth flow: shows the brand mark plus a "1/2" step
/// badge — the same pattern [OnboardingWelcomeScreen] uses to open the
/// onboarding flow. The next screen (OTP) drops the logo and advances the
/// badge to "2/2", exactly like [PartnerBenefitsScreen] does for onboarding.
class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: IconButtonCustom(
              icon: LucideIcons.arrowLeft,
              tooltip: 'Back',
              onPressed: onBack,
            ),
          ),
          const QikzooPartnerLogo(
            width: 150,
            alignment: Alignment.center,
          ),
          const Positioned(right: 0, child: _StepBadge(current: 1, total: 2)),
        ],
      ),
    );
  }
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

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.flow,
    required this.controller,
    required this.phone,
    required this.isPhoneValid,
    required this.isRequesting,
    required this.isCompact,
    required this.onPhoneChanged,
    required this.onContinue,
    required this.onSubmitted,
  });

  final AuthFlow flow;
  final TextEditingController controller;
  final String phone;
  final bool isPhoneValid;
  final bool isRequesting;
  final bool isCompact;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback? onContinue;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isLogin = flow == AuthFlow.login;
    final title = isLogin ? 'Welcome Back!' : 'Create your partner account';
    final subtitle = isLogin
        ? 'Use your registered mobile number to continue to your partner dashboard.'
        : 'Enter your mobile number to start your Qikzoo partner journey.';

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isLogin ? 'PARTNER LOGIN' : 'NEW PARTNER',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: AppTypography.h1.copyWith(
              fontSize: isCompact ? 22 : 25,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF162B4D),
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: isCompact ? 13.5 : 14.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Secure OTP - No password',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.lg),
          const _FieldLabel(text: 'Mobile number'),
          const SizedBox(height: 6),
          PhoneInputField(
            controller: controller,
            enabled: !isRequesting,
            isValid: isPhoneValid,
            onChanged: onPhoneChanged,
            onSubmitted: onSubmitted,
          ),
          const SizedBox(height: AppSpacing.md),
          _PhoneStatusLines(
            phone: phone,
            isValid: isPhoneValid,
          ),
          SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.lg),
          PrimaryCtaButton(
            label: 'Continue',
            trailingIcon: LucideIcons.arrowRight,
            isLoading: isRequesting,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        color: const Color(0xFF162B4D),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PhoneStatusLines extends StatelessWidget {
  const _PhoneStatusLines({
    required this.phone,
    required this.isValid,
  });

  final String phone;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    final hasInput = phone.isNotEmpty;
    final hasTenDigits = phone.length == 10;

    String mainMessage = 'We will send a 4-digit OTP to verify this number.';
    Color mainColor = AppColors.textSecondary;
    IconData mainIcon = LucideIcons.info;

    if (hasInput) {
      if (isValid) {
        mainMessage = 'Number looks good';
        mainColor = AppColors.success;
        mainIcon = LucideIcons.checkCircle2;
      } else if (!hasTenDigits) {
        mainMessage = 'Enter all 10 digits of your mobile number.';
        mainColor = AppColors.error;
        mainIcon = LucideIcons.alertCircle;
      } else {
        mainMessage = 'Enter a valid 10-digit Indian mobile number.';
        mainColor = AppColors.error;
        mainIcon = LucideIcons.alertCircle;
      }
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(mainIcon, size: 16, color: mainColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                mainMessage,
                style: AppTypography.caption
                    .copyWith(color: mainColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(LucideIcons.helpCircle,
                  size: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Lost access to your number? Qikzoo support can help.',
                style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegalNotice extends StatelessWidget {
  const _LegalNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'By continuing, you agree to Qikzoo Terms and Conditions.',
      child: ExcludeSemantics(
        child: Text(
          'By continuing, you agree to Qikzoo Terms and Conditions.',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
