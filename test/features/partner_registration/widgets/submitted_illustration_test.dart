import 'package:delivery_partner_app/core/assets/app_assets.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/submitted_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the accessible 3D submitted-application asset',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SubmittedIllustration())),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Verified application checklist'),
      findsOneWidget,
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
    final resizedImage = image.image as ResizeImage;
    expect(resizedImage.imageProvider, isA<AssetImage>());
    expect(
      (resizedImage.imageProvider as AssetImage).assetName,
      AppAssets.applicationSubmitted3d,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
