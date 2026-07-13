import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class SwipeActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onConfirmed;
  final IconData icon;

  const SwipeActionButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.icon = LucideIcons.chevronsRight,
  });

  @override
  State<SwipeActionButton> createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<SwipeActionButton> {
  static const double _height = 56;
  static const double _thumb = 48;
  double _dx = 0;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDx = constraints.maxWidth - _thumb - 8;
        final progress = maxDx <= 0 ? 0.0 : (_dx / maxDx).clamp(0.0, 1.0);

        void onDragUpdate(DragUpdateDetails d) {
          if (_confirmed) return;
          setState(() => _dx = (_dx + d.delta.dx).clamp(0.0, maxDx));
        }

        void onDragEnd(DragEndDetails _) {
          if (_confirmed) return;
          final endProgress = maxDx <= 0 ? 0.0 : (_dx / maxDx).clamp(0.0, 1.0);
          if (endProgress >= 0.85) {
            setState(() {
              _dx = maxDx;
              _confirmed = true;
            });
            HapticFeedback.lightImpact();
            widget.onConfirmed();
          } else {
            setState(() => _dx = 0);
          }
        }

        return GestureDetector(
          onHorizontalDragUpdate: onDragUpdate,
          onHorizontalDragEnd: onDragEnd,
          child: SizedBox(
            height: _height,
            width: double.infinity,
            child: Stack(
              children: [
                // Track + gradient fill following the thumb.
                Container(
                  height: _height,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: _dx + _thumb + 4,
                        decoration: const BoxDecoration(
                          gradient:
                              LinearGradient(colors: AppColors.ctaGradient),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Opacity(
                    opacity: (1 - progress).clamp(0.0, 1.0),
                    child: Text(
                      widget.label,
                      style: AppTypography.button
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                Positioned(
                  left: 4 + _dx,
                  top: 4,
                  child: Container(
                    width: _thumb,
                    height: _thumb,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Icon(
                      _confirmed ? LucideIcons.check : widget.icon,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
