import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';

/// Large, tactile selfie capture control with press and loading animations.
class CaptureButton extends StatefulWidget {
  const CaptureButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.semanticLabel = 'Capture selfie',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String semanticLabel;

  @override
  State<CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<CaptureButton> {
  bool _isPressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _handleHighlight(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 120);

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: duration,
          width: 84,
          height: 84,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color:
                  AppColors.primary.withValues(alpha: _enabled ? 0.20 : 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.primary.withValues(alpha: _enabled ? 0.28 : 0.08),
                blurRadius: _isPressed ? 12 : 24,
                offset: Offset(0, _isPressed ? 4 : 10),
              ),
            ],
          ),
          child: Material(
            color: _enabled ? AppColors.primary : AppColors.textDisabled,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _enabled ? widget.onPressed : null,
              onHighlightChanged: _handleHighlight,
              child: Center(
                child: AnimatedSwitcher(
                  duration: duration,
                  child: widget.isLoading
                      ? const SizedBox(
                          key: ValueKey('capture-progress'),
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.6,
                          ),
                        )
                      : const Icon(
                          LucideIcons.camera,
                          key: ValueKey('capture-icon'),
                          color: Colors.white,
                          size: 30,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
