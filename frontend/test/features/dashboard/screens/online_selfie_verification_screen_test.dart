import 'package:delivery_partner_app/features/dashboard/screens/online_selfie_verification_screen.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_image_picker.dart';
import 'package:delivery_partner_app/shared/widgets/buttons/primary_cta_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class FakeDocumentImagePicker implements DocumentImagePicker {
  ImageSource? lastSource;

  @override
  Future<String?> pickImage(ImageSource source) async {
    lastSource = source;
    return '/tmp/shift-selfie.jpg';
  }
}

void setPhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildScreen(FakeDocumentImagePicker picker) {
  return ProviderScope(
    overrides: [
      documentImagePickerProvider.overrideWithValue(
        picker,
      ),
    ],
    child: const MaterialApp(home: OnlineSelfieVerificationScreen()),
  );
}

void main() {
  testWidgets('explains all selfie requirements before upload', (tester) async {
    setPhoneSurface(tester);
    await tester.pumpWidget(buildScreen(FakeDocumentImagePicker()));

    expect(find.text('One quick check before\nyou go online'), findsOneWidget);
    expect(find.text('White T-shirt'), findsOneWidget);
    expect(find.text('Good lighting'), findsOneWidget);
    expect(find.text('Face visible'), findsOneWidget);
    final uploadButton = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(uploadButton.onPressed, isNull);
  });

  testWidgets('camera capture enables submit and shows retake state',
      (tester) async {
    setPhoneSurface(tester);
    final picker = FakeDocumentImagePicker();
    await tester.pumpWidget(buildScreen(picker));

    expect(find.text('Upload from gallery'), findsNothing);
    expect(find.text('Camera only • fresh photo required'), findsOneWidget);

    await tester.tap(find.text('Tap to open camera'));
    await tester.pumpAndSettle();

    expect(picker.lastSource, ImageSource.camera);
    expect(find.text('Selfie added'), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);

    final uploadButton = tester.widget<PrimaryCtaButton>(
      find.byType(PrimaryCtaButton),
    );
    expect(uploadButton.onPressed, isNotNull);
  });
}
