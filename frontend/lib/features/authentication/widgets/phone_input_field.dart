import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isValid;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    this.isValid = false,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isValid
        ? AppColors.success
        : _focusNode.hasFocus
            ? AppColors.secondary
            : AppColors.border;

    return Semantics(
      textField: true,
      label: 'Indian mobile number',
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.quick),
        curve: AppMotion.enter,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: borderColor,
            width: _focusNode.hasFocus || widget.isValid ? 1.5 : 1,
          ),
          boxShadow: _focusNode.hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    blurRadius: 0,
                    spreadRadius: 4,
                  ),
                ]
              : const [],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'IN',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('+91', style: AppTypography.bodyMedium),
                ],
              ),
            ),
            Container(width: 1, height: 30, color: AppColors.border),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    hintText: '98765 43210',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.45),
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.quick),
              child: widget.isValid
                  ? const Padding(
                      key: ValueKey('valid-phone'),
                      padding: EdgeInsets.only(right: AppSpacing.md),
                      child: Icon(
                        LucideIcons.checkCircle2,
                        color: AppColors.success,
                        size: 21,
                      ),
                    )
                  : const SizedBox(width: AppSpacing.md),
            ),
          ],
        ),
      ),
    );
  }
}
