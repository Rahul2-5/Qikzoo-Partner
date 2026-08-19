import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/outlined_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/layout/glass_container.dart';

class CancelOrderSheet {
  CancelOrderSheet._();

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const GlassBottomSheet(
        child: _CancelOrderSheetContent(),
      ),
    );
  }
}

class _CancelOrderSheetContent extends StatefulWidget {
  const _CancelOrderSheetContent();

  @override
  State<_CancelOrderSheetContent> createState() =>
      _CancelOrderSheetContentState();
}

class _CancelOrderSheetContentState extends State<_CancelOrderSheetContent> {
  static const _reasons = [
    'Restaurant delay',
    'Customer unavailable',
    'Wrong address',
    'Vehicle issue',
    'Accident/emergency',
    'Restaurant closed',
    'Other',
  ];

  final _otherController = TextEditingController();
  String? _selectedReason;

  bool get _isOther => _selectedReason == 'Other';

  String? get _submission {
    final selected = _selectedReason;
    if (selected == null) return null;
    if (!_isOther) return selected;
    final details = _otherController.text.trim();
    return details.isEmpty ? null : 'Other: $details';
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Cancel this order?', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Choose the reason that best describes the situation.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: _reasons
                .map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: _selectedReason == reason
                          ? AppColors.error.withValues(alpha: 0.08)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _selectedReason = reason),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedReason == reason
                                  ? AppColors.error
                                  : AppColors.border,
                              width: _selectedReason == reason ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  reason,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: _selectedReason == reason
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _selectedReason == reason
                                        ? AppColors.error
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedReason == reason
                                        ? AppColors.error
                                        : AppColors.textDisabled,
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: _selectedReason == reason
                                    ? Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.error,
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (_isOther) ...[
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _otherController,
              label: 'Tell us what happened',
              hint: 'Enter cancellation details',
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
          ],
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
                  backgroundColor: AppColors.error,
                  onPressed: _submission == null
                      ? null
                      : () => Navigator.of(context).pop(_submission),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
