import 'package:delivery_partner_app/features/partner_registration/screens/selfie_camera_capture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

    expect(find.text('Selfie Verification'), findsOneWidget);
    expect(find.text('Place your face inside the circle'), findsOneWidget);
    expect(find.text('Remove glasses'), findsOneWidget);
    expect(find.text('Align your face inside the frame'), findsNothing);
    expect(find.textContaining('camera could not be started'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
