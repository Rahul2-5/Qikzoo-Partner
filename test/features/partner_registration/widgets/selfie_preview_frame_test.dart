import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/selfie_preview_frame.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows a placeholder icon when there is no profile photo yet', (tester) async {
    await tester.pumpWidget(wrap(const SelfiePreviewFrame(profilePhoto: null)));

    expect(find.byIcon(LucideIcons.userCircle), findsOneWidget);
  });

  testWidgets('renders an image widget when the profile photo is uploaded', (tester) async {
    await tester.pumpWidget(wrap(const SelfiePreviewFrame(
      profilePhoto: DocumentModel(
        type: DocumentType.profilePhoto,
        status: DocumentStatus.pendingVerification,
        fileUrl: '/tmp/selfie.jpg',
      ),
    )));

    expect(find.byType(Image), findsOneWidget);
  });
}
