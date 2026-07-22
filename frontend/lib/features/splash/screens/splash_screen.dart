import 'package:delivery_partner_app/models/authentication/session_restore_outcome.dart';
import 'package:delivery_partner_app/providers/authentication/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Minimum time the brand animation stays on screen before acting on the
  /// session-restore result, so a fast/cached restore never reads as a
  /// flicker. Session restore itself has no artificial delay or retry
  /// loop beyond this — a single attempt per tap, so there's no splash
  /// loop if the backend is down.
  Future<void> _bootstrap() async {
    final delay = Future.delayed(const Duration(milliseconds: 2200));
    final result = await ref.read(authSessionProvider.notifier).restoreSession();
    await delay;
    if (!mounted) return;
    _handleResult(result);
  }

  /// Active/needsOnboarding both carry a [SessionRestoreResult.route]
  /// already resolved through `NextOnboardingStepResolver` inside
  /// `restoreSession()` — this screen never derives a destination itself,
  /// so there is exactly one place in the app that maps onboarding status
  /// to a route. loggedOut/offline never reach that resolver (no status
  /// was fetched), so they keep their own fixed handling here.
  void _handleResult(SessionRestoreResult result) {
    switch (result.outcome) {
      case SessionRestoreOutcome.active:
      case SessionRestoreOutcome.needsOnboarding:
        _navigateTo(result.route ?? AppRoutes.verificationStatus);
      case SessionRestoreOutcome.loggedOut:
        _navigateTo(AppRoutes.welcome);
      case SessionRestoreOutcome.offline:
        // A saved session must not make the app unusable when the API is
        // briefly unavailable. Let the rider continue to sign in; a
        // successful sign-in replaces the saved session.
        _navigateTo(AppRoutes.welcome);
    }
  }

  void _navigateTo(String route) {
    setState(() => _exiting = true);
    Future.delayed(AppMotion.duration(context, AppMotion.standard), () {
      if (mounted) Get.offAllNamed(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCompact = screenHeight < 720;
    final riderHeight =
        isCompact ? 245.0 : screenHeight >= 900 ? 340.0 : 310.0;
    const logoRed = Color(0xFFFF3D1F);
    const logoBlue = Color(0xFF0E43B7);
    const splashBackground = Color(0xFFF8FBFF);
    final glow = Container(
      width: 360,
      height: riderHeight * 0.78,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            logoBlue.withValues(alpha: 0.16),
            logoRed.withValues(alpha: 0.08),
            splashBackground.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
    final logo = Image.asset(
      AppAssets.brandLogo,
      width: isCompact ? 210 : 240,
      height: isCompact ? 64 : 76,
      fit: BoxFit.contain,
    );
    final riderIllustration = Image.asset(
      AppAssets.happyDeliveryRider3d,
      height: riderHeight,
      fit: BoxFit.contain,
      semanticLabel: 'Happy Qikzoo delivery partner on a scooter',
    );
    final appDescriptor = Text(
      'DELIVERY PARTNER APP',
      style: AppTypography.caption.copyWith(
        color: AppColors.primary,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
    final tagline = Text(
      'Kaam pe aate-jaate,\nkamaai bhi badhaate.',
      style: AppTypography.h2.copyWith(
        color: AppColors.primaryDark,
        fontSize: isCompact ? 18 : 21,
        fontWeight: FontWeight.w800,
        height: 1.22,
      ),
      textAlign: TextAlign.center,
    );

    return Scaffold(
      backgroundColor: splashBackground,
      body: Center(
        child: AnimatedOpacity(
          opacity: _exiting ? 0 : 1,
          duration: AppMotion.duration(context, AppMotion.standard),
          curve: AppMotion.enter,
          child: AnimatedScale(
            scale: _exiting ? 0.92 : 1,
            duration: AppMotion.duration(context, AppMotion.standard),
            curve: AppMotion.enter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (reduceMotion)
                      glow
                    else
                      glow
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                            begin: 0.85,
                            end: 1.15,
                            duration: 1400.ms,
                            curve: Curves.easeInOut,
                          )
                          .fadeIn(duration: 600.ms),
                    if (reduceMotion)
                      riderIllustration
                    else
                      riderIllustration
                          .animate()
                          .scale(
                            begin: const Offset(0.82, 0.82),
                            end: const Offset(1, 1),
                            duration: 650.ms,
                            curve: Curves.easeOutBack,
                          )
                          .fadeIn(duration: 400.ms),
                  ],
                ),
                SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.sm),
                if (reduceMotion)
                  logo
                else
                  logo
                      .animate(delay: 280.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        duration: 350.ms,
                        curve: Curves.easeOut,
                      ),
                const SizedBox(height: AppSpacing.xs),
                if (reduceMotion)
                  appDescriptor
                else
                  appDescriptor
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                const SizedBox(height: AppSpacing.sm),
                if (reduceMotion)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: tagline,
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: tagline
                        .animate(delay: 720.ms)
                        .fadeIn(duration: 420.ms)
                        .slideY(
                          begin: 0.25,
                          end: 0,
                          duration: 420.ms,
                          curve: Curves.easeOut,
                        ),
                  ),
                SizedBox(height: isCompact ? AppSpacing.lg : AppSpacing.xl),
                _PulsingDots(
                  activeColor: logoRed,
                  idleColor: logoBlue,
                  motionEnabled: !reduceMotion,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDots extends StatelessWidget {
  const _PulsingDots({
    required this.activeColor,
    required this.idleColor,
    required this.motionEnabled,
  });

  final Color activeColor;
  final Color idleColor;
  final bool motionEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final dot = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == 0 ? activeColor : idleColor.withValues(alpha: 0.72),
            ),
          ),
        );
        if (!motionEnabled) return dot;
        return dot
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
              delay: (i * 150).ms,
            )
            .scaleXY(begin: 0.6, end: 1.2, duration: 500.ms)
            .fadeIn(begin: 0.4, duration: 500.ms);
      }),
    );
  }
}

/// network/server — keeps the rider on the splash screen with a manual
