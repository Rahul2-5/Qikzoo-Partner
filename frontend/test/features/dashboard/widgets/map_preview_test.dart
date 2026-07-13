import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/widgets/map_preview.dart';

void main() {
  testWidgets('MapPreview renders at the requested height', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: MapPreview(height: 150))),
    ));
    final box = tester.getSize(find.byType(MapPreview));
    expect(box.height, 150);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
