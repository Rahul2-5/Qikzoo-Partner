import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/authentication/auth_flow.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale =
                  MediaQuery.textScalerOf(context).scale(1).clamp(1, 3);
              final isCompact = constraints.maxWidth < 360 ||
                  constraints.maxHeight < 700 ||
                  textScale > 1.3;
              final useWideLayout = constraints.maxWidth >= 720 ||
                  (constraints.maxWidth >= 600 && constraints.maxHeight <= 520);
              final horizontalPadding = switch (constraints.maxWidth) {
                < 360 => AppSpacing.sm + AppSpacing.xs,
                < 600 => AppSpacing.md,
                < 960 => AppSpacing.lg,
                _ => AppSpacing.xl,
              };
              final verticalPadding = isCompact ? AppSpacing.sm : AppSpacing.md;

              return Stack(
                children: [
                  const Positioned.fill(
                    child: RepaintBoundary(child: _LightLoginBackdrop()),
                  ),
                  Positioned.fill(
                    child: FocusTraversalGroup(
                      child: CustomScrollView(
                        key: const ValueKey('mobile-number-scroll-view'),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: verticalPadding,
                            ),
                            sliver: SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1120,
                                  ),
                                  child: useWideLayout
                                      ? _WideLoginLayout(
                                          flow: flow,
                                          controller: controller,
                                          phone: phone,
                                          isPhoneValid: isPhoneValid,
                                          isRequesting: isRequesting,
                                          isCompact: isCompact,
                                          onBack: onBack,
                                          onPhoneChanged: onPhoneChanged,
                                          onContinue: onContinue,
                                          onSubmitted: onSubmitted,
                                        )
                                      : _NarrowLoginLayout(
                                          flow: flow,
                                          controller: controller,
                                          phone: phone,
                                          isPhoneValid: isPhoneValid,
                                          isRequesting: isRequesting,
                                          isCompact: isCompact,
                                          onBack: onBack,
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
                  ),
                ],
              );
            },
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
    required this.onBack,
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
  final VoidCallback onBack;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback? onContinue;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LoginTopBar(
            onBack: onBack,
            logoWidth: isCompact ? 164 : 196,
          ),
          SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.md),
          AppStaggeredReveal(
            index: 1,
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
          const SizedBox(height: AppSpacing.md),
          const AppStaggeredReveal(index: 2, child: _LegalNotice()),
        ],
      ),
    );
  }
}

class _WideLoginLayout extends StatelessWidget {
  const _WideLoginLayout({
    required this.flow,
    required this.controller,
    required this.phone,
    required this.isPhoneValid,
    required this.isRequesting,
    required this.isCompact,
    required this.onBack,
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
  final VoidCallback onBack;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback? onContinue;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AppStaggeredReveal(
            index: 0,
            child: IconButtonCustom(
              icon: LucideIcons.arrowLeft,
              tooltip: 'Back',
              onPressed: onBack,
            ),
          ),
        ),
        SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: AppStaggeredReveal(
                index: 1,
                child: _WideBrandPanel(isCompact: isCompact),
              ),
            ),
            SizedBox(width: isCompact ? AppSpacing.lg : AppSpacing.xl),
            Expanded(
              flex: 6,
              child: Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppStaggeredReveal(
                        index: 2,
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
                      const SizedBox(height: AppSpacing.md),
                      const _LegalNotice(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoginTopBar extends StatelessWidget {
  const _LoginTopBar({
    required this.onBack,
    required this.logoWidth,
  });

  final VoidCallback onBack;
  final double logoWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppStaggeredReveal(
              index: 0,
              child: IconButtonCustom(
                icon: LucideIcons.arrowLeft,
                tooltip: 'Back',
                onPressed: onBack,
              ),
            ),
          ),
          AppStaggeredReveal(
            index: 0,
            child: _BrandLogo(width: logoWidth),
          ),
        ],
      ),
    );
  }
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
    final title = isLogin ? 'Welcome back' : 'Create your partner account';
    final subtitle = isLogin
        ? 'Use your registered mobile number to continue to your partner dashboard.'
        : 'Enter your mobile number to start your Qikzoo partner journey.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.9),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isCompact ? AppSpacing.md : AppSpacing.lg,
        ),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isLogin ? 'PARTNER LOGIN' : 'NEW PARTNER',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: AppTypography.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _SecurityNote(),
              SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.lg),
              Text('Mobile number', style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              PhoneInputField(
                controller: controller,
                enabled: !isRequesting,
                isValid: isPhoneValid,
                onChanged: onPhoneChanged,
                onSubmitted: onSubmitted,
              ),
              const SizedBox(height: AppSpacing.sm),
              _PhoneStatus(
                phone: phone,
                isValid: isPhoneValid,
              ),
              const SizedBox(height: AppSpacing.md),
              const _SupportNote(),
              SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.lg),
              PrimaryCtaButton(
                label: 'Continue',
                trailingIcon: LucideIcons.arrowRight,
                isLoading: isRequesting,
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneStatus extends StatelessWidget {
  const _PhoneStatus({
    required this.phone,
    required this.isValid,
  });

  final String phone;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    final hasInput = phone.isNotEmpty;
    final hasTenDigits = phone.length == 10;
    final message = switch ((hasInput, isValid, hasTenDigits)) {
      (false, _, _) => 'We will send a 4-digit OTP to verify this number.',
      (_, true, _) => 'Number looks good',
      (_, false, false) => 'Enter all 10 digits of your mobile number.',
      _ => 'Enter a valid 10-digit Indian mobile number.',
    };
    final color = isValid
        ? AppColors.success
        : hasTenDigits
            ? AppColors.error
            : AppColors.textSecondary;
    final icon = isValid
        ? LucideIcons.checkCircle2
        : hasTenDigits
            ? LucideIcons.alertCircle
            : LucideIcons.info;

    return Semantics(
      liveRegion: hasInput,
      label: message,
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration: AppMotion.duration(context, AppMotion.quick),
          child: Row(
            key: ValueKey(message),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.caption.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Secure OTP access. No password required.',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primarySoft.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + AppSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.shieldCheck,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Secure OTP - No password',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
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

class _SupportNote extends StatelessWidget {
  const _SupportNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            LucideIcons.helpCircle,
            size: 17,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Lost access to your number? Qikzoo support can help.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
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
          ),
        ),
      ),
    );
  }
}

class _WideBrandPanel extends StatelessWidget {
  const _WideBrandPanel({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final illustrationHeight = isCompact ? 136.0 : 232.0;
    final decodeHeight =
        (illustrationHeight * MediaQuery.devicePixelRatioOf(context)).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F2FF), Color(0xFFFBFCFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isCompact ? AppSpacing.md : AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BrandLogo(width: isCompact ? 184 : 220),
            SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.lg),
            Text(
              'Your partner journey starts here.',
              style: isCompact ? AppTypography.h2 : AppTypography.display,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Secure access to deliveries, earnings, and everything you need on the road.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.md),
            Center(
              child: RepaintBoundary(
                child: Image.asset(
                  AppAssets.riderScooterIndigo3d,
                  height: illustrationHeight,
                  cacheHeight: decodeHeight,
                  fit: BoxFit.contain,
                  semanticLabel: 'Qikzoo delivery partner riding a scooter',
                ),
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(height: AppSpacing.md),
              const Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _FeaturePill(
                    icon: LucideIcons.shieldCheck,
                    label: 'Secure OTP',
                  ),
                  _FeaturePill(
                    icon: LucideIcons.clock3,
                    label: 'Quick access',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 0.31;
    final decodeWidth =
        (width * MediaQuery.devicePixelRatioOf(context)).round();

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          minWidth: width,
          maxWidth: width,
          minHeight: width,
          maxHeight: width,
          alignment: Alignment.center,
          child: Image.asset(
            AppAssets.mainLogo,
            width: width,
            height: width,
            cacheWidth: decodeWidth,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            semanticLabel: 'Qikzoo Delivery Partner',
          ),
        ),
      ),
    );
  }
}

class _LightLoginBackdrop extends StatelessWidget {
  const _LightLoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFAFBFF), AppColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -110,
            child: _BackdropOrb(
              size: 320,
              color: AppColors.secondary.withValues(alpha: 0.09),
            ),
          ),
          Positioned(
            bottom: -170,
            left: -130,
            child: _BackdropOrb(
              size: 360,
              color: AppColors.primary.withValues(alpha: 0.07),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
