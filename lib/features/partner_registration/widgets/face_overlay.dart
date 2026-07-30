import 'package:flutter/material.dart';

/// Paints the secure face-guide treatment over a camera preview.
///
/// The middle remains transparent, while the small area outside the guide is
/// darkened. This widget does not inspect or detect a face.
class FaceOverlay extends StatelessWidget {
  const FaceOverlay({
    super.key,
    this.guideInset = 12,
    this.borderWidth = 4,
  });

  final double guideInset;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _FaceOverlayPainter(
            guideInset: guideInset,
            borderWidth: borderWidth,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _FaceOverlayPainter extends CustomPainter {
  const _FaceOverlayPainter({
    required this.guideInset,
    required this.borderWidth,
  });

  final double guideInset;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = Offset.zero & size;
    final shortestSide = size.shortestSide;
    final guideRect = Rect.fromCenter(
      center: outerRect.center,
      width: shortestSide - (guideInset * 2),
      height: shortestSide - (guideInset * 2),
    );

    final overlayPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(
        center: outerRect.center,
        radius: shortestSide / 2,
      ))
      ..addOval(guideRect);
    canvas.drawPath(
      overlayPath,
      Paint()..color = const Color(0x99000000),
    );

    // A separate blurred stroke creates a restrained halo without softening
    // the crisp 4 px guide itself.
    canvas.drawOval(
      guideRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 5
        ..color = Colors.white.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawOval(
      guideRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_FaceOverlayPainter oldDelegate) {
    return oldDelegate.guideInset != guideInset ||
        oldDelegate.borderWidth != borderWidth;
  }
}
