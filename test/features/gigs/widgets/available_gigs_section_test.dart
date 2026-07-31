import 'package:delivery_partner_app/features/gigs/widgets/available_gigs_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('benefit values stay inside a compact gig card', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GigOfferCard(gig: availableGigs.first),
          ),
        ),
      ),
    );

    expect(find.text('2 Hour Delivery Gig'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
