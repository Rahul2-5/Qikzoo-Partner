import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/selfie_verification_screen.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_image_picker.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_repository.dart';

class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository(this._documents);
  List<DocumentModel> _documents;

  @override
  Future<List<DocumentModel>> getDocuments() async => _documents;

  @override
  Future<DocumentModel> uploadDocument(
      DocumentType type, String filePath) async {
    final updated = DocumentModel(
      type: type,
      status: DocumentStatus.pendingVerification,
      fileUrl: filePath,
    );
    _documents = [
      for (final doc in _documents)
        if (doc.type == type) updated else doc,
    ];
    return updated;
  }
}

class FakeDocumentImagePicker implements DocumentImagePicker {
  @override
  Future<String?> pickImage(ImageSource source) async => '/tmp/selfie.jpg';
}

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp(List<DocumentModel> documents) {
  return ProviderScope(
    overrides: [
      documentRepositoryProvider
          .overrideWithValue(FakeDocumentRepository(documents)),
      documentImagePickerProvider.overrideWithValue(FakeDocumentImagePicker()),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.selfieVerification,
      getPages: [
        GetPage(
          name: AppRoutes.selfieVerification,
          page: () => const SelfieVerificationScreen(),
        ),
        GetPage(
          name: AppRoutes.welcomeKit,
          page: () => const Scaffold(body: Text('Welcome Kit Screen')),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('shows Capture initially and the verification tips',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp([
      const DocumentModel(
          type: DocumentType.profilePhoto, status: DocumentStatus.notUploaded),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Capture'), findsOneWidget);
    expect(find.text('Make sure your face is clearly visible'), findsOneWidget);
    expect(find.text('Good lighting'), findsOneWidget);
    expect(find.text('No sunglasses or filters'), findsOneWidget);
  });

  testWidgets('capturing and using a photo switches Capture to Continue',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp([
      const DocumentModel(
          type: DocumentType.profilePhoto, status: DocumentStatus.notUploaded),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Capture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Photo'));
    await tester.pumpAndSettle();

    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets(
      'Continue navigates to Welcome Kit once the selfie is uploaded',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp([
      const DocumentModel(
        type: DocumentType.profilePhoto,
        status: DocumentStatus.pendingVerification,
        fileUrl: '/tmp/existing.jpg',
      ),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Kit Screen'), findsOneWidget);
  });
}
