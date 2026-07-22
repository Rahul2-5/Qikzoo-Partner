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
import '../../../core/constants/app_constants.dart';
import '../../../models/authentication/session_restore_outcome.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../shared/widgets/buttons/outlined_button_custom.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _exiting = false;
  bool _showRetry = false;

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
    final outcome = await ref.read(authSessionProvider.notifier).restoreSession();
    await delay;
    if (!mounted) return;
    _handleOutcome(outcome);
  }

  Future<void> _retry() async {
    setState(() => _showRetry = false);
    final outcome = await ref.read(authSessionProvider.notifier).restoreSession();
    if (!mounted) return;
    _handleOutcome(outcome);
  }

  void _handleOutcome(SessionRestoreOutcome outcome) {
    switch (outcome) {
      case SessionRestoreOutcome.active:
        _navigateTo(AppRoutes.dashboard);
      case SessionRestoreOutcome.needsOnboarding:
        _navigateTo(AppRoutes.verificationStatus);
      case SessionRestoreOutcome.loggedOut:
        _navigateTo(AppRoutes.welcome);
      case SessionRestoreOutcome.offline:
        setState(() => _showRetry = true);
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
    const logoRed = Color(0xFFFF3D1F);
    const logoBlue = Color(0xFF0E43B7);
    const splashBackground = Color(0xFFF8FBFF);
    final glow = Container(
      width: 320,
      height: 220,
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
      width: 260,
      height: 100,
      fit: BoxFit.contain,
    );
    final title = Text(
      AppConstants.appName,
      style: AppTypography.h1.copyWith(
        color: AppColors.textPrimary,
        fontSize: 28,
      ),
    );
    final tagline = Text(
      'Delivering Opportunities',
      style: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
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
                      logo
                    else
                      logo
                          .animate()
                          .scale(
                            begin: const Offset(0.4, 0.4),
                            end: const Offset(1, 1),
                            duration: 700.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: 400.ms),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (reduceMotion)
                  title
                else
                  title.animate(delay: 500.ms).fadeIn(duration: 400.ms).slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                const SizedBox(height: AppSpacing.xs),
                if (reduceMotion)
                  tagline
                else
                  tagline
                      .animate(delay: 800.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                const SizedBox(height: AppSpacing.xl),
                if (_showRetry)
                  _ConnectionRetry(onRetry: _retry)
                else
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

/// Shown in place of the pulsing dots when session restore can't reach the
/// network/server — keeps the rider on the splash screen with a manual
/// retry instead of silently looping or bouncing them to login.
class _ConnectionRetry extends StatelessWidget {
  const _ConnectionRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Couldn't connect. Check your internet and try again.",
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: 160,
          child: OutlinedButtonCustom(label: 'Retry', onPressed: onRetry),
        ),
      ],
    );
  }
}
