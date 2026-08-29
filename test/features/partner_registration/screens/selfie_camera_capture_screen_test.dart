import 'dart:io';

import 'package:camera/camera.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/selfie_camera_capture_screen.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/capture_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_camera.dart';

void main() {
  testWidgets('is scroll-safe on a compact phone when camera is unavailable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: SelfieCameraCaptureScreen(
          cameraListLoader: () async => const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Face verification'), findsOneWidget);
    // 'Place your face inside the circle' / 'Remove glasses' never existed
    // in this screen (grep confirms 'Remove glasses' only lives in the
    // unrelated InstructionCard widget, which SelfieCameraCaptureScreen
    // never uses) — dropped rather than pointed at nonexistent copy. The
    // neutral face-guide message ('Align your face inside the frame') is
    // correctly absent here for a different, real reason: with no camera
    // available _cameraError is set, so _buildBottomSection's status switch
    // shows the error message instead of the neutral guide.
    expect(find.text('Align your face inside the frame'), findsNothing);
    expect(find.textContaining('camera could not be started'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'camera permission denied shows the real error state, never a fake selfie',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: SelfieCameraCaptureScreen(
          cameraListLoader: fakeCameraListLoader,
          controllerBuilder: (description) => FakeCameraController(
            description,
            behavior: FakeCameraBehavior(
              initializeError: CameraException(
                'CameraAccessDenied',
                'Camera permission was denied by the user.',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The error appears both in the camera guide and the status card below
    // it, mirroring the screen's existing "camera unavailable" behavior.
    expect(
      find.textContaining('Camera access is required'),
      findsWidgets,
    );
    // No selfie can have been captured — the capture button is present but
    // disabled, since the camera never reported itself as ready.
    expect(
      tester.widget<CaptureButton>(find.byType(CaptureButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a successful capture pops the real captured file path to the caller',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? poppedPath;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              poppedPath = await Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) => SelfieCameraCaptureScreen(
                    cameraListLoader: fakeCameraListLoader,
                    controllerBuilder: (description) =>
                        FakeCameraController(description),
                  ),
                ),
              );
            },
            child: const Text('Open camera'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CaptureButton));
    await tester.pumpAndSettle();

    // `SelfieImageProcessor.prepareForUpload` performs real `dart:io` file
    // I/O, which the virtualized test clock can't advance — the triggering
    // tap must run inside `runAsync` so that real work actually completes.
    await tester.runAsync(() async {
      await tester.tap(find.byType(CaptureButton));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(poppedPath, isNotNull);
    expect(poppedPath, endsWith('selfie.jpg'));
    expect(File(poppedPath!).existsSync(), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a capture failure shows a retryable error and keeps the camera open',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: SelfieCameraCaptureScreen(
          cameraListLoader: fakeCameraListLoader,
          controllerBuilder: (description) => FakeCameraController(
            description,
            behavior: FakeCameraBehavior(
              captureError: CameraException(
                'capture_failure',
                'The shutter failed to fire.',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CaptureButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();

    expect(
      find.text('We could not capture your selfie. Please try again.'),
      findsOneWidget,
    );
    // Still on the camera screen with a live capture button — a failed
    // capture must never silently return a fabricated selfie to the caller.
    expect(find.byType(CaptureButton), findsOneWidget);
    expect(find.text('Face verification'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
