import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class GreetingHeader extends StatelessWidget {
  final bool online;
  final VoidCallback onToggleStatus;

  const GreetingHeader({
    super.key,
    required this.online,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          header: true,
          label: 'Qikzoo Partner',
          excludeSemantics: true,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.ctaGradient,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Text(
                  'Q',
                  style: AppTypography.h2.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QIKZOO',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'PARTNER',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: online
              ? 'Currently online. Change status'
              : 'Currently offline. Change status',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleStatus,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: AnimatedContainer(
                duration: AppMotion.duration(context, AppMotion.standard),
                curve: AppMotion.enter,
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: online ? AppColors.successBg : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                    color: online
                        ? AppColors.success.withValues(alpha: 0.24)
                        : AppColors.border,
                  ),
                  boxShadow: AppShadows.control,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: online
                            ? AppColors.success
                            : AppColors.textSecondary,
                        shape: BoxShape.circle,
                        boxShadow: online
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.success.withValues(alpha: 0.32),
                                  blurRadius: 7,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      online ? 'Online' : 'Offline',
                      style: AppTypography.bodyMedium.copyWith(
                        color:
                            online ? AppColors.success : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      LucideIcons.chevronDown,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
