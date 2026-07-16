import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/misc/app_3d_illustration.dart';

class WaitingForOrdersCard extends StatefulWidget {
  const WaitingForOrdersCard({super.key});

  @override
  State<WaitingForOrdersCard> createState() => _WaitingForOrdersCardState();
}

class _WaitingForOrdersCardState extends State<WaitingForOrdersCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.ambient,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _controller
        ..stop()
        ..value = 0.35;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, Color(0xFFECFBF6)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.sheet + 2),
        border: Border.all(color: AppColors.surface),
        boxShadow: AppShadows.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 500;
          final radar = _OrderRadar(controller: _controller);
          const message = _WaitingMessage();

          if (horizontal) {
            return Row(
              children: [
                radar,
                const SizedBox(width: AppSpacing.xl),
                const Expanded(child: message),
              ],
            );
          }

          return Column(
            children: [
              radar,
              const SizedBox(height: AppSpacing.md),
              message,
            ],
          );
        },
      ),
    );
  }
}

class _OrderRadar extends StatelessWidget {
  final AnimationController controller;

  const _OrderRadar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);

    return Semantics(
      image: true,
      label: 'Searching for nearby delivery orders',
      excludeSemantics: true,
      child: SizedBox(
        height: 126,
        width: 126,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                _pulse(reduceMotion ? 0.35 : 0),
                _pulse(reduceMotion ? 0.7 : 0.5),
                const App3dIllustration(
                  assetPath: AppAssets.orderSearch3d,
                  semanticLabel: 'Searching nearby for delivery orders',
                  size: 116,
                  glowColor: AppColors.secondary,
                  fallbackIcon: LucideIcons.bike,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pulse(double offset) {
    final t = (controller.value + offset) % 1.0;
    return Opacity(
      opacity: (1 - t).clamp(0.0, 1.0) * 0.35,
      child: Container(
        width: 64 + t * 62,
        height: 64 + t * 62,
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _WaitingMessage extends StatelessWidget {
  const _WaitingMessage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.radio,
                  color: AppColors.success,
                  size: 14,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'YOU ARE ONLINE',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Finding orders near you…',
          textAlign: TextAlign.center,
          style: AppTypography.h2.copyWith(fontSize: 20),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Stay ready. A new delivery request can arrive at any moment.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
