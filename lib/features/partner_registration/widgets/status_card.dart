import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum SelfieStatusTone { neutral, busy, error }

/// Animated floating feedback shown immediately above the capture control.
class SelfieStatusCard extends StatelessWidget {
  const SelfieStatusCard({
    super.key,
    this.message = 'Align your face inside the frame',
    this.tone = SelfieStatusTone.neutral,
  });

  final String message;
  final SelfieStatusTone tone;

  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 280);
    final foreground = switch (tone) {
      SelfieStatusTone.neutral => const Color(0xFF334155),
      SelfieStatusTone.busy => _primary,
      SelfieStatusTone.error => const Color(0xFFB42318),
    };
    final background = switch (tone) {
      SelfieStatusTone.neutral => Colors.white,
      SelfieStatusTone.busy => const Color(0xFFEFF6FF),
      SelfieStatusTone.error => const Color(0xFFFFF1F0),
    };
    final icon = switch (tone) {
      SelfieStatusTone.neutral => LucideIcons.scanFace,
      SelfieStatusTone.busy => LucideIcons.loader2,
      SelfieStatusTone.error => LucideIcons.alertCircle,
    };

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: foreground.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Row(
          key: ValueKey('$tone-$message'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
