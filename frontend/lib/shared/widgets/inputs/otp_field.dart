import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class OtpField extends StatelessWidget {
  final int length;
  final void Function(String) onCompleted;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final bool readOnly;

  const OtpField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth =
            ((constraints.maxWidth - ((length - 1) * 8)) / length)
                .clamp(40.0, 52.0);

        return PinCodeTextField(
          appContext: context,
          length: length,
          controller: controller,
          readOnly: readOnly,
          onCompleted: onCompleted,
          onChanged: onChanged ?? (_) {},
          keyboardType: TextInputType.number,
          animationType: AnimationType.fade,
          enableActiveFill: true,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textStyle: AppTypography.h2,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(AppRadius.control),
            fieldHeight: 54,
            fieldWidth: fieldWidth,
            activeColor: AppColors.secondary,
            selectedColor: AppColors.secondary,
            inactiveColor: AppColors.border,
            activeFillColor: AppColors.surface,
            selectedFillColor: AppColors.surface,
            inactiveFillColor: AppColors.surface,
          ),
        );
      },
    );
  }
}
