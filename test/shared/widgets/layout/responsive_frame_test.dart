import 'package:delivery_partner_app/shared/widgets/layout/responsive_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildFrame({double maxWidth = 520}) {
  return MaterialApp(
    home: Scaffold(
      body: ResponsiveFrame(
        maxWidth: maxWidth,
        child: const SizedBox(
          key: ValueKey('responsive-content'),
          height: 20,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('uses compact gutters without shrinking narrow-phone content',
      (tester) async {
    setSurfaceSize(tester, const Size(320, 640));

    await tester.pumpWidget(buildFrame());

    final content =
        tester.getRect(find.byKey(const ValueKey('responsive-content')));
    expect(content.left, 12);
    expect(content.right, 308);
    expect(content.width, 296);
    expect(tester.takeException(), isNull);
  });

  testWidgets('centers and bounds content on wide windows', (tester) async {
    setSurfaceSize(tester, const Size(1024, 768));

    await tester.pumpWidget(buildFrame());

    final content =
        tester.getRect(find.byKey(const ValueKey('responsive-content')));
    expect(content.left, 276);
    expect(content.right, 748);
    expect(content.width, 472);
    expect(tester.takeException(), isNull);
  });
}
