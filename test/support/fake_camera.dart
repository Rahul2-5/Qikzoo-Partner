import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;

/// A deterministic stand-in for the native `camera` plugin used by widget
/// tests that exercise the real selfie-capture flow.
///
/// [CameraController] normally forwards every operation to
/// `CameraPlatform.instance`, which talks to a native platform channel that
/// doesn't exist in the `flutter_test` VM. Rather than swap the whole
/// platform-interface singleton, this subclass overrides just the three
/// entry points [SelfieCameraCaptureScreen] actually calls —
/// [initialize], [takePicture], and [buildPreview] — so it never touches a
/// platform channel while still behaving like a real, initialized camera to
/// everything above it (including [CameraPreview] and the confirm/upload
/// flow, which reads a real, decodable JPEG off disk).
class FakeCameraController extends CameraController {
  FakeCameraController(CameraDescription description, {this.behavior})
      : super(description, ResolutionPreset.high, enableAudio: false);

  /// Injected per-test to simulate failures; defaults to a happy path.
  final FakeCameraBehavior? behavior;

  @override
  Future<void> initialize() async {
    final failure = behavior?.initializeError;
    if (failure != null) throw failure;
    value = value.copyWith(
      isInitialized: true,
      previewSize: const Size(1080, 1920),
    );
  }

  @override
  Future<XFile> takePicture() async {
    final failure = behavior?.captureError;
    if (failure != null) throw failure;

    // Synchronous I/O: widget tests virtualize the async clock, and real
    // asynchronous filesystem callbacks are not guaranteed to be pumped
    // promptly inside a full app (Riverpod + GetX) widget tree, so this
    // avoids depending on that entirely rather than racing it.
    final tempDir = Directory.systemTemp.createTempSync('fake_selfie');
    final file = File('${tempDir.path}/selfie.jpg');
    final placeholder = image.Image(width: 4, height: 4);
    file.writeAsBytesSync(image.encodeJpg(placeholder), flush: true);
    return XFile(file.path);
  }

  @override
  Widget buildPreview() => const ColoredBox(color: Color(0xFF0F172A));

  @override
  Future<void> dispose() async {
    // The real dispose() only reaches the platform channel once
    // `initialize()`'s private future has been set — this fake never calls
    // it, so the inherited implementation is already a safe no-op.
    await super.dispose();
  }
}

/// Lets a test simulate a specific camera failure without special-casing
/// production code.
class FakeCameraBehavior {
  const FakeCameraBehavior({this.initializeError, this.captureError});

  final CameraException? initializeError;
  final CameraException? captureError;
}

Future<List<CameraDescription>> fakeCameraListLoader() async => const [
      CameraDescription(
        name: 'fake-front-camera',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 0,
      ),
    ];

/// Empty camera list, for simulating "no camera available on this device".
Future<List<CameraDescription>> fakeEmptyCameraListLoader() async => const [];
