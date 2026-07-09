import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class IconButtonCustom extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  const IconButtonCustom({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
        ),
      ),
    );
  }
}
