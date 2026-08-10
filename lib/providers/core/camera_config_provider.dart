import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/partner_registration/screens/selfie_camera_capture_screen.dart';

/// The camera dependencies used to capture a rider's verification selfie.
///
/// Production code never overrides [cameraConfigProvider], so every real
/// build resolves to the real `camera` plugin via [availableCameras] and the
/// default [CameraController]. Widget tests override the provider with a
/// deterministic fake camera list/controller so the real selfie flow —
/// capture, confirm, upload — can be exercised without native camera
/// hardware.
class CameraConfig {
  const CameraConfig({
    this.cameraListLoader = availableCameras,
    this.controllerBuilder,
  });

  final CameraListLoader cameraListLoader;

  /// Null in production, which makes [SelfieCameraCaptureScreen] build a
  /// real [CameraController]. Tests supply a builder that returns a fake.
  final SelfieCameraControllerBuilder? controllerBuilder;
}

final cameraConfigProvider =
    Provider<CameraConfig>((ref) => const CameraConfig());
