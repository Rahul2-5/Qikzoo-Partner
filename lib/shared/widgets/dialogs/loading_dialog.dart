import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../layout/glass_container.dart';

class LoadingDialog {
  LoadingDialog._();

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const GlassDialog(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: CircularProgressIndicator(color: AppColors.secondary),
      ),
    );
  }
}
