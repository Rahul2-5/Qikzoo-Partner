import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/document_upload_screen.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';
import 'package:delivery_partner_app/providers/document_verification/documents_provider.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_repository.dart';

class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository(this._documents);
  final List<DocumentModel> _documents;

  @override
  Future<List<DocumentModel>> getDocuments() async => _documents;

  @override
  Future<DocumentModel> uploadDocument(DocumentType type, String filePath) async {
    return DocumentModel(type: type, status: DocumentStatus.pendingVerification, fileUrl: filePath);
  }
}

Widget buildApp(List<DocumentModel> documents) {
  return ProviderScope(
    overrides: [
      documentRepositoryProvider.overrideWithValue(FakeDocumentRepository(documents)),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.documentUpload,
      getPages: [
        GetPage(name: AppRoutes.documentUpload, page: () => const DocumentUploadScreen()),
        GetPage(
          name: AppRoutes.bankDetails,
          page: () => const Scaffold(body: Text('Bank Details Screen')),
        ),
      ],
    ),
  );
}

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  test('missingRequiredDocumentLabels lists only missing required docs, PAN excluded', () {
    final documents = [
      const DocumentModel(type: DocumentType.aadhaar, status: DocumentStatus.pendingVerification),
      const DocumentModel(type: DocumentType.drivingLicense, status: DocumentStatus.notUploaded),
      const DocumentModel(type: DocumentType.vehicleRc, status: DocumentStatus.verified),
      const DocumentModel(type: DocumentType.vehicleInsurance, status: DocumentStatus.rejected),
      const DocumentModel(type: DocumentType.pan, status: DocumentStatus.notUploaded),
    ];

    expect(
      missingRequiredDocumentLabels(documents),
      ['Driving License', 'Insurance'],
    );
  });

  testWidgets('renders all five documents in order', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp(
      DocumentType.values
          .map((type) => DocumentModel(type: type, status: DocumentStatus.notUploaded))
          .toList(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Aadhaar Card'), findsOneWidget);
    expect(find.text('Driving License'), findsOneWidget);
    expect(find.text('Vehicle RC'), findsOneWidget);
    expect(find.text('Insurance'), findsOneWidget);
    expect(find.textContaining('PAN Card'), findsOneWidget);
  });

  testWidgets('Continue shows a snackbar listing missing required documents', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp(
      DocumentType.values
          .map((type) => DocumentModel(type: type, status: DocumentStatus.notUploaded))
          .toList(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aadhaar Card'), findsWidgets);
    expect(find.text('Bank Details Screen'), findsNothing);
  });

  testWidgets('Continue navigates to bank details once required documents are uploaded', (tester) async {
    setTallSurface(tester);
    const requiredTypes = [
      DocumentType.aadhaar,
      DocumentType.drivingLicense,
      DocumentType.vehicleRc,
      DocumentType.vehicleInsurance,
    ];
    final documents = DocumentType.values.map((type) {
      final isRequired = requiredTypes.contains(type);
      return DocumentModel(
        type: type,
        status: isRequired ? DocumentStatus.pendingVerification : DocumentStatus.notUploaded,
        fileUrl: isRequired ? '/tmp/${type.name}.jpg' : null,
      );
    }).toList();

    await tester.pumpWidget(buildApp(documents));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Bank Details Screen'), findsOneWidget);
  });
}
