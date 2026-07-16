import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';

class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.primary;
    final iconBackground = destructive
        ? AppColors.error.withValues(alpha: 0.1)
        : AppColors.primarySoft;
    return AppPressEffect(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(AppRadius.control)),
                    child: Icon(icon, size: 19, color: color),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppTypography.bodyMedium
                                .copyWith(color: color)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: AppTypography.caption),
                      ],
                    ),
                  ),
                  if (!destructive)
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.sm),
                      child: Icon(LucideIcons.chevronRight,
                          size: 19, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
