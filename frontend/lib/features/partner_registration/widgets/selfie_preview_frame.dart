import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/document_verification/document_model.dart';

class SelfiePreviewFrame extends StatelessWidget {
  final DocumentModel? profilePhoto;

  const SelfiePreviewFrame({super.key, this.profilePhoto});

  bool get _hasPhoto {
    final photo = profilePhoto;
    return photo?.fileUrl != null &&
        (photo!.status == DocumentStatus.pendingVerification ||
            photo.status == DocumentStatus.verified);
  }

  @override
  Widget build(BuildContext context) {
    const size = 180.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DashedGradientRingPainter(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipOval(
            child: _hasPhoto
                ? Image.file(
                    File(profilePhoto!.fileUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceMuted,
        alignment: Alignment.center,
        child: const Icon(
          LucideIcons.userCircle,
          size: 72,
          color: AppColors.textSecondary,
        ),
      );
}

class _DashedGradientRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2 - 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(colors: AppColors.ctaGradient).createShader(rect);

    const dashCount = 24;
    const gapFraction = 0.4;
    const sweep = (2 * math.pi / dashCount) * (1 - gapFraction);
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
