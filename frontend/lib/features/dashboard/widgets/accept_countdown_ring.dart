import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AcceptCountdownRing extends StatefulWidget {
  final int seconds;
  final VoidCallback onExpired;
  final double size;

  const AcceptCountdownRing({
    super.key,
    required this.seconds,
    required this.onExpired,
    this.size = 60,
  });

  static Color colorForRemaining(int remaining) {
    if (remaining <= 4) return AppColors.error;
    if (remaining <= 9) return AppColors.warning;
    return AppColors.success;
  }

  @override
  State<AcceptCountdownRing> createState() => _AcceptCountdownRingState();
}

class _AcceptCountdownRingState extends State<AcceptCountdownRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && !_fired) {
          _fired = true;
          widget.onExpired();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (widget.seconds * (1 - _controller.value))
        .ceil()
        .clamp(0, widget.seconds);
    final color = AcceptCountdownRing.colorForRemaining(remaining);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _RingPainter(progress: 1 - _controller.value, color: color),
        child: Center(
          child: Text(
            '$remaining',
            style: AppTypography.numericMd.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final track = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
