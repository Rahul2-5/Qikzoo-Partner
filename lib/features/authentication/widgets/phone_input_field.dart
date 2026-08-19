import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

const _qikzooNavy = Color(0xFF162B4D);

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isValid;
  final bool enabled;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    this.isValid = false,
    this.enabled = true,
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
    final borderColor = !widget.enabled
        ? AppColors.border
        : widget.isValid
            ? AppColors.success
            : _focusNode.hasFocus
                ? AppColors.primary
                : AppColors.border;

    return Semantics(
      container: true,
      label: 'Indian mobile number, country code plus 91',
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.quick),
        curve: AppMotion.enter,
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: widget.enabled ? AppColors.surface : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: borderColor,
            width: widget.enabled && (_focusNode.hasFocus || widget.isValid)
                ? 1.5
                : 1,
          ),
          boxShadow: widget.enabled && _focusNode.hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                  ExcludeSemantics(
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        'IN',
                        maxLines: 1,
                        style: AppTypography.caption.copyWith(
                          color: _qikzooNavy,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ExcludeSemantics(
                    child: Text('+91', style: AppTypography.bodyMedium),
                  ),
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
                  enabled: widget.enabled,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  textDirection: TextDirection.ltr,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  onTapOutside: (_) => _focusNode.unfocus(),
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
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    hintText: '10 digits',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.45),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.quick),
              child: widget.enabled && widget.isValid
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
