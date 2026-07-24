import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/document_upload_actions.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';
import 'package:delivery_partner_app/models/partner_registration/personal_info_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/providers/document_verification/documents_provider.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_image_picker.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_repository.dart';
import 'package:delivery_partner_app/repositories/profile/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  int uploadSelfieCalls = 0;
  String? lastSelfiePath;
  Object? uploadSelfieError;

  @override
  Future<PartnerProfileModel> uploadSelfie(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    uploadSelfieCalls++;
    lastSelfiePath = file.path;
    if (uploadSelfieError != null) throw uploadSelfieError!;
    return PartnerProfileModel(
      id: 'rider-1',
      name: 'Test Rider',
      phone: '9876543210',
      joinedDate: DateTime(2026, 1, 1),
      selfieUrl: file.path,
    );
  }

  @override
  Future<PartnerProfileModel> getProfile() => throw UnimplementedError();

  @override
  Future<RatingModel> getRating() => throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updatePersonalDetails({
    required String name,
    String? email,
    required DateTime dateOfBirth,
    required Gender gender,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> uploadProfilePhoto(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updateAddress({
    required String addressLine1,
    String? addressLine2,
    String? landmark,
    required String city,
    required String state,
    required String pincode,
    double? addressLat,
    double? addressLng,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updateEmergencyContact({
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) =>
      throw UnimplementedError();
}

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

  testWidgets('Use Photo uploads the selfie through the real profile API',
      (tester) async {
    final profileRepository = FakeProfileRepository();
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(profileRepository),
        documentImagePickerProvider.overrideWithValue(FakeDocumentImagePicker()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => pickAndConfirmSelfie(context, ref),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();

    expect(find.text('Use Photo'), findsOneWidget);
    await tester.tap(find.text('Use Photo'));
    await tester.pumpAndSettle();

    expect(profileRepository.uploadSelfieCalls, 1);
    expect(profileRepository.lastSelfiePath, '/tmp/picked.jpg');
  });

  testWidgets('Retake reopens the source sheet without uploading', (tester) async {
    final profileRepository = FakeProfileRepository();
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(profileRepository),
        documentImagePickerProvider.overrideWithValue(FakeDocumentImagePicker()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => pickAndConfirmSelfie(context, ref),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retake'));
    await tester.pumpAndSettle();

    expect(find.text('Take Photo'), findsOneWidget);
    expect(profileRepository.uploadSelfieCalls, 0);
  });
}
