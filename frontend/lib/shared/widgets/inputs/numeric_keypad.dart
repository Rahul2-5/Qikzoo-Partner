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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondaryBg, AppColors.accentBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in _rows) ...[
            Row(children: row.map(_buildKey).toList()),
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
                  child: const Icon(LucideIcons.delete, color: AppColors.textPrimary, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String digit) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: _KeypadButton(
          onTap: () => onDigitTap(digit),
          child: Text(digit, style: AppTypography.h2.copyWith(fontSize: 22)),
        ),
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
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
