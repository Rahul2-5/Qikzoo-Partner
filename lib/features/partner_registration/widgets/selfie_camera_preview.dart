import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays a camera texture using a centre-crop while preserving its native
/// aspect ratio.
///
/// A [CameraPreview] must not be forced into the size of its parent. The
/// preview is first laid out at the camera's correctly oriented aspect ratio,
/// then uniformly enlarged until it covers the viewport. Any excess is
/// clipped, exactly like `BoxFit.cover`, so faces are never stretched.
class SelfieCameraPreview extends StatelessWidget {
  const SelfieCameraPreview({
    super.key,
    required this.controller,
    this.alignment = Alignment.center,
  });

  final CameraController controller;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CameraValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final previewSize = value.previewSize;
        if (!value.isInitialized || previewSize == null) {
          return const SizedBox.expand();
        }

        final orientation = value.previewPauseOrientation ??
            value.lockedCaptureOrientation ??
            value.deviceOrientation;
        final orientedSize = _orientedPreviewSize(
          previewSize,
          orientation,
        );

        return ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (!constraints.hasBoundedWidth ||
                  !constraints.hasBoundedHeight ||
                  constraints.maxWidth <= 0 ||
                  constraints.maxHeight <= 0) {
                return const SizedBox.shrink();
              }

              final viewport = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final fittedSize = calculateCoverSize(
                source: orientedSize,
                destination: viewport,
              );

              return OverflowBox(
                alignment: alignment,
                minWidth: fittedSize.width,
                maxWidth: fittedSize.width,
                minHeight: fittedSize.height,
                maxHeight: fittedSize.height,
                child: SizedBox.fromSize(
                  size: fittedSize,
                  child: AspectRatio(
                    aspectRatio: orientedSize.aspectRatio,
                    child: CameraPreview(controller),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Returns dimensions that match the same device orientation used
  /// internally by [CameraPreview].
  static Size _orientedPreviewSize(
    Size preview,
    DeviceOrientation orientation,
  ) {
    final isLandscape = orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;

    if (isLandscape) return preview;
    return Size(preview.height, preview.width);
  }

  /// Calculates a uniform scale that completely covers [destination].
  ///
  /// This helper is public to make the no-distortion invariant easy to test.
  @visibleForTesting
  static Size calculateCoverSize({
    required Size source,
    required Size destination,
  }) {
    assert(source.width > 0 && source.height > 0);
    assert(destination.width > 0 && destination.height > 0);

    final scale = math.max(
      destination.width / source.width,
      destination.height / source.height,
    );
    return Size(source.width * scale, source.height * scale);
  }
}
