import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class OtpField extends StatelessWidget {
  final int length;
  final void Function(String) onCompleted;
  final void Function(String)? onChanged;

  const OtpField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      appContext: context,
      length: length,
      onCompleted: onCompleted,
      onChanged: onChanged ?? (_) {},
      keyboardType: TextInputType.number,
      animationType: AnimationType.fade,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(AppRadius.button),
        fieldHeight: 52,
        fieldWidth: 44,
        activeColor: AppColors.secondary,
        selectedColor: AppColors.secondary,
        inactiveColor: AppColors.textSecondary.withValues(alpha: 0.3),
        activeFillColor: AppColors.surface,
        selectedFillColor: AppColors.surface,
        inactiveFillColor: AppColors.surface,
      ),
    );
  }
}
