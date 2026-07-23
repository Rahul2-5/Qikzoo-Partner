import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/inputs/otp_field.dart';

/// Bottom sheet collecting the 6-digit delivery OTP the customer reads out
/// to the rider. Returns the entered code, or `null` if dismissed.
class DeliveryOtpSheet {
  DeliveryOtpSheet._();

  static Future<String?> show(
    BuildContext context, {
    required int attemptsRemaining,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => _DeliveryOtpSheetContent(attemptsRemaining: attemptsRemaining),
    );
  }
}

class _DeliveryOtpSheetContent extends StatefulWidget {
  final int attemptsRemaining;

  const _DeliveryOtpSheetContent({required this.attemptsRemaining});

  @override
  State<_DeliveryOtpSheetContent> createState() => _DeliveryOtpSheetContentState();
}

class _DeliveryOtpSheetContentState extends State<_DeliveryOtpSheetContent> {
  String _code = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Enter delivery OTP', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ask the customer for the 6-digit code sent to their phone.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          OtpField(
            length: 6,
            onChanged: (v) => setState(() => _code = v),
            onCompleted: (v) => setState(() => _code = v),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${widget.attemptsRemaining} attempt${widget.attemptsRemaining == 1 ? '' : 's'} remaining',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryCtaButton(
            label: 'Confirm delivery',
            onPressed: _code.length == 6
                ? () => Navigator.of(context).pop(_code)
                : null,
          ),
        ],
      ),
    );
  }
}
