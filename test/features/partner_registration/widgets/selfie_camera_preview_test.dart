import 'package:delivery_partner_app/features/partner_registration/widgets/selfie_camera_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelfieCameraPreview.calculateCoverSize', () {
    test('covers a square without changing a landscape source ratio', () {
      const source = Size(1920, 1080);
      const destination = Size.square(300);

      final fitted = SelfieCameraPreview.calculateCoverSize(
        source: source,
        destination: destination,
      );

      expect(fitted.width, closeTo(533.33, 0.01));
      expect(fitted.height, closeTo(300, 0.01));
      expect(fitted.aspectRatio, closeTo(source.aspectRatio, 0.0001));
      expect(fitted.width, greaterThanOrEqualTo(destination.width));
      expect(fitted.height, greaterThanOrEqualTo(destination.height));
    });

    test('covers a square without changing a portrait source ratio', () {
      const source = Size(1080, 1920);
      const destination = Size.square(300);

      final fitted = SelfieCameraPreview.calculateCoverSize(
        source: source,
        destination: destination,
      );

      expect(fitted.width, closeTo(300, 0.01));
      expect(fitted.height, closeTo(533.33, 0.01));
      expect(fitted.aspectRatio, closeTo(source.aspectRatio, 0.0001));
      expect(fitted.width, greaterThanOrEqualTo(destination.width));
      expect(fitted.height, greaterThanOrEqualTo(destination.height));
    });
  });
}
