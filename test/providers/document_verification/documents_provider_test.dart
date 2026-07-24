import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';
import 'package:delivery_partner_app/providers/document_verification/documents_provider.dart';
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

void main() {
  test('remove resets a document back to notUploaded and clears its file', () async {
    final container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          FakeDocumentRepository([
            const DocumentModel(
              type: DocumentType.aadhaar,
              status: DocumentStatus.pendingVerification,
              fileUrl: '/tmp/aadhaar.jpg',
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(documentsProvider.future);
    container.read(documentsProvider.notifier).remove(DocumentType.aadhaar);

    final updated = container.read(documentsProvider).value!.single;
    expect(updated.status, DocumentStatus.notUploaded);
    expect(updated.fileUrl, isNull);
  });
}
