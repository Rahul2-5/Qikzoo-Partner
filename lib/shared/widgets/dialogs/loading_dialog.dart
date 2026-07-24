import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class LoadingDialog {
  LoadingDialog._();

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      ),
    );
  }
}
