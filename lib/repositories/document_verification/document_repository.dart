import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/document_verification/document_model.dart';

abstract class DocumentRepository {
  Future<List<DocumentModel>> getDocuments();
  Future<DocumentModel> uploadDocument(DocumentType type, String filePath);
}

class MockDocumentRepository implements DocumentRepository {
  @override
  Future<List<DocumentModel>> getDocuments() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return DocumentType.values
        .map((type) => DocumentModel(type: type, status: DocumentStatus.notUploaded))
        .toList();
  }

  @override
  Future<DocumentModel> uploadDocument(DocumentType type, String filePath) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return DocumentModel(
      type: type,
      status: DocumentStatus.pendingVerification,
      fileUrl: filePath,
    );
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) => MockDocumentRepository());
