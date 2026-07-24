import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/outlined_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';

/// Bottom sheet collecting a mandatory cancellation reason before calling
/// `POST /rider/orders/:id/cancel` — the backend requires a non-empty
/// `reason` string (`CancelRiderOrderDto`), so this can't be skipped.
/// Returns the entered reason, or `null` if dismissed.
class CancelOrderSheet {
  CancelOrderSheet._();

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => const _CancelOrderSheetContent(),
    );
  }
}

class _CancelOrderSheetContent extends StatefulWidget {
  const _CancelOrderSheetContent();

  @override
  State<_CancelOrderSheetContent> createState() => _CancelOrderSheetContentState();
}

class _CancelOrderSheetContentState extends State<_CancelOrderSheetContent> {
  final _controller = TextEditingController();
  String _reason = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          Text('Cancel this order?', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tell us why — this helps us support you and the customer.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _controller,
            label: 'Reason',
            hint: 'e.g. Vehicle breakdown',
            onChanged: (v) => setState(() => _reason = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButtonCustom(
                  label: 'Keep order',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PrimaryCtaButton(
                  label: 'Cancel order',
                  onPressed: _reason.trim().isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_reason.trim()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
