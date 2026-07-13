import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class MapPreview extends StatelessWidget {
  final double height;
  final bool showRoute;

  const MapPreview({super.key, this.height = 150, this.showRoute = true});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _MapPainter(showRoute: showRoute),
          child: showRoute
              ? const Stack(
                  children: [
                    Align(
                      alignment: Alignment(-0.8, 0.2),
                      child: _MapMarker(
                          icon: LucideIcons.store, color: AppColors.secondary),
                    ),
                    Align(
                      alignment: Alignment(0.82, -0.2),
                      child: _MapMarker(
                          icon: LucideIcons.mapPin, color: AppColors.primary),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _MapMarker({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}

class _MapPainter extends CustomPainter {
  final bool showRoute;
  _MapPainter({required this.showRoute});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFEAF0F6);
    canvas.drawRect(Offset.zero & size, bg);

    // Soft "parks"
    final park = Paint()..color = const Color(0xFFD8EBDA);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 26, park);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.25), 20, park);

    // Roads
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.55),
        Offset(size.width, size.height * 0.42), road);
    canvas.drawLine(Offset(size.width * 0.45, 0),
        Offset(size.width * 0.55, size.height), road);

    if (showRoute) {
      final start = Offset(size.width * 0.1, size.height * 0.6);
      final end = Offset(size.width * 0.9, size.height * 0.4);
      final control = Offset(size.width * 0.5, size.height * 0.15);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      _drawDashedPath(
          canvas,
          path,
          Paint()
            ..color = AppColors.secondary
            ..strokeWidth = 3.5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dash = 9.0, gap = 6.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.showRoute != showRoute;
}
