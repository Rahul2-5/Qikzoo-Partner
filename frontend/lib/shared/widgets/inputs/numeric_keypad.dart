import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// In-app numeric keypad (digits 0-9 + backspace) for PIN/OTP-style inputs
/// that want a controlled, app-native entry surface instead of the system
/// keyboard.
class NumericKeypad extends StatelessWidget {
  final void Function(String digit) onDigitTap;
  final VoidCallback onBackspaceTap;

  const NumericKeypad({
    super.key,
    required this.onDigitTap,
    required this.onBackspaceTap,
  });

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in _rows) ...[
            _buildRow(row),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              const Expanded(child: SizedBox()),
              const SizedBox(width: AppSpacing.sm),
              _buildKey('0'),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _KeypadButton(
                  onTap: onBackspaceTap,
                  child: const Icon(LucideIcons.delete,
                      color: AppColors.textPrimary, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> row) {
    return Row(
      children: [
        for (var index = 0; index < row.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          _buildKey(row[index]),
        ],
      ],
    );
  }

  Widget _buildKey(String digit) {
    return Expanded(
      child: _KeypadButton(
        onTap: () => onDigitTap(digit),
        child: Text(digit, style: AppTypography.h2.copyWith(fontSize: 22)),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _KeypadButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
