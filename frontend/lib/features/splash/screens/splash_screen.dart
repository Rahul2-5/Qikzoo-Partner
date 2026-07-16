import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

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
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _exiting = true);
      Future.delayed(AppMotion.duration(context, AppMotion.standard), () {
        if (mounted) Get.offAllNamed(AppRoutes.welcome);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);
    final glow = Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.16),
            AppColors.secondary.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
    final logo = Image.asset(
      'assets/images/logo.png',
      width: 180,
      height: 180,
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
      backgroundColor: AppColors.surface,
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
                _PulsingDots(motionEnabled: !reduceMotion),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDots extends StatelessWidget {
  const _PulsingDots({required this.motionEnabled});

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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary,
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
