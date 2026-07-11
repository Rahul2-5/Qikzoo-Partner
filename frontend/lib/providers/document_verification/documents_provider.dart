import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/document_verification/document_repository.dart';
import '../../models/document_verification/document_model.dart';

class DocumentsNotifier extends AsyncNotifier<List<DocumentModel>> {
  @override
  Future<List<DocumentModel>> build() => ref.watch(documentRepositoryProvider).getDocuments();

  Future<void> upload(DocumentType type, String filePath) async {
    final updated = await ref.read(documentRepositoryProvider).uploadDocument(type, filePath);
    state = AsyncData([
      for (final doc in state.value ?? [])
        if (doc.type == type) updated else doc,
    ]);
  }
}

final documentsProvider = AsyncNotifierProvider<DocumentsNotifier, List<DocumentModel>>(
  DocumentsNotifier.new,
);
