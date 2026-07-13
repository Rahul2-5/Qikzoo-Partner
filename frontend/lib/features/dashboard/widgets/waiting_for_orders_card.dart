import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

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
      duration: const Duration(milliseconds: 1800),
    )..repeat();
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _pulse(0),
                    _pulse(0.5),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.bike,
                          color: Colors.white, size: 26),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Finding orders near you…', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "You're online. Stay ready — a request can arrive any moment.",
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _pulse(double offset) {
    final t = (_controller.value + offset) % 1.0;
    return Opacity(
      opacity: (1 - t).clamp(0.0, 1.0) * 0.4,
      child: Container(
        width: 60 + t * 60,
        height: 60 + t * 60,
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
