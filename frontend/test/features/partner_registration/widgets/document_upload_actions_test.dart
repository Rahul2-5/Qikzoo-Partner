import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/document_upload_actions.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';
import 'package:delivery_partner_app/providers/document_verification/documents_provider.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_image_picker.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_repository.dart';

class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository(this._documents);
  List<DocumentModel> _documents;

  @override
  Future<List<DocumentModel>> getDocuments() async => _documents;

  @override
  Future<DocumentModel> uploadDocument(DocumentType type, String filePath) async {
    final updated = DocumentModel(
      type: type,
      status: DocumentStatus.pendingVerification,
      fileUrl: filePath,
    );
    _documents = [
      for (final doc in _documents) if (doc.type == type) updated else doc,
    ];
    return updated;
  }
}

class FakeDocumentImagePicker implements DocumentImagePicker {
  @override
  Future<String?> pickImage(ImageSource source) async => '/tmp/picked.jpg';
}

void main() {
  testWidgets('picking Take Photo uploads the document', (tester) async {
    final container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          FakeDocumentRepository([
            const DocumentModel(type: DocumentType.aadhaar, status: DocumentStatus.notUploaded),
          ]),
        ),
        documentImagePickerProvider.overrideWithValue(FakeDocumentImagePicker()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(documentsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => pickAndUploadDocument(context, ref, DocumentType.aadhaar),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);

    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();

    final updated = container
        .read(documentsProvider)
        .value!
        .firstWhere((doc) => doc.type == DocumentType.aadhaar);
    expect(updated.status, DocumentStatus.pendingVerification);
    expect(updated.fileUrl, '/tmp/picked.jpg');
  });

  testWidgets('Remove resets the document to notUploaded', (tester) async {
    final container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          FakeDocumentRepository([
            const DocumentModel(
              type: DocumentType.aadhaar,
              status: DocumentStatus.pendingVerification,
              fileUrl: '/tmp/a.jpg',
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final documents = await container.read(documentsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDocumentPreviewSheet(context, ref, documents.first),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Replace'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    final updated = container.read(documentsProvider).value!.single;
    expect(updated.status, DocumentStatus.notUploaded);
  });
}
