import 'package:flutter/material.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../motion/app_motion_widgets.dart';

class OrderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressEffect(
      enabled: onTap != null,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Ink(
            decoration: GlassTheme.surface(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.bodyMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(subtitle, style: AppTypography.caption),
                      ],
                    ),
                  ),
                  Text(amount, style: AppTypography.numericMd),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
