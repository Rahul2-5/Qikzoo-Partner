import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/document_upload_tile.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('not uploaded shows Upload label and is tappable',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(DocumentUploadTile(
      document: const DocumentModel(
          type: DocumentType.aadhaar, status: DocumentStatus.notUploaded),
      onTap: () => tapped = true,
    )));

    expect(find.text('Upload'), findsOneWidget);
    await tester.tap(find.byType(DocumentUploadTile));
    expect(tapped, isTrue);
  });

  testWidgets('uploading shows a spinner instead of the status icon',
      (tester) async {
    await tester.pumpWidget(wrap(DocumentUploadTile(
      document: const DocumentModel(
          type: DocumentType.aadhaar, status: DocumentStatus.uploading),
      onTap: () {},
    )));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('uploaded shows Uploaded label', (tester) async {
    await tester.pumpWidget(wrap(DocumentUploadTile(
      document: const DocumentModel(
        type: DocumentType.aadhaar,
        status: DocumentStatus.pendingVerification,
        fileUrl: '/tmp/a.jpg',
      ),
      onTap: () {},
    )));

    expect(find.text('Uploaded'), findsOneWidget);
  });

  testWidgets('rejected shows the rejection reason', (tester) async {
    await tester.pumpWidget(wrap(DocumentUploadTile(
      document: const DocumentModel(
        type: DocumentType.aadhaar,
        status: DocumentStatus.rejected,
        rejectionReason: 'Image is blurry',
      ),
      onTap: () {},
    )));

    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Image is blurry'), findsOneWidget);
  });

  testWidgets('insurance shows the optional suffix', (tester) async {
    await tester.pumpWidget(wrap(DocumentUploadTile(
      document: const DocumentModel(
          type: DocumentType.vehicleInsurance,
          status: DocumentStatus.notUploaded),
      onTap: () {},
    )));

    expect(find.textContaining('(Optional)'), findsOneWidget);
  });

  testWidgets('PAN card shows the required suffix', (tester) async {
    await tester.pumpWidget(wrap(DocumentUploadTile(
      document: const DocumentModel(
          type: DocumentType.pan, status: DocumentStatus.notUploaded),
      onTap: () {},
    )));

    expect(find.textContaining('(Required)'), findsOneWidget);
    expect(find.textContaining('(Optional)'), findsNothing);
  });
}
