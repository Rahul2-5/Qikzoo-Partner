import 'package:delivery_partner_app/shared/widgets/navigation/app_tab_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildShell({ValueChanged<int>? onDestinationSelected}) => MaterialApp(
      home: Scaffold(
        body: AppTabScaffold(
          currentIndex: 0,
          onDestinationSelected: onDestinationSelected,
          child: const Center(child: Text('Content')),
        ),
      ),
    );

void main() {
  testWidgets('uses the floating navigation on a compact phone',
      (tester) async {
    setSurfaceSize(tester, const Size(390, 844));

    await tester.pumpWidget(buildShell());

    expect(find.byKey(const Key('compact-tab-navigation')), findsOneWidget);
    expect(find.byKey(const Key('expanded-tab-navigation')), findsNothing);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('uses a labelled rail and preserves tab actions on wide windows',
      (tester) async {
    setSurfaceSize(tester, const Size(1024, 768));
    int? selectedIndex;

    await tester.pumpWidget(
      buildShell(onDestinationSelected: (index) => selectedIndex = index),
    );

    expect(find.byKey(const Key('expanded-tab-navigation')), findsOneWidget);
    expect(find.byKey(const Key('compact-tab-navigation')), findsNothing);
    expect(find.text('Content'), findsOneWidget);

    await tester.tap(find.text('Orders'));
    await tester.pump();
    expect(selectedIndex, 2);
  });
}
