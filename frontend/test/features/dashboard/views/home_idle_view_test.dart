import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/views/home_idle_view.dart';

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('offline state shows the offline hero', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(wrap(HomeIdleView(
      online: false,
      onGoOnline: () {},
      onGoOffline: () {},
    )));
    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Go Online'), findsOneWidget);
  });

  testWidgets('online state shows the waiting card and Go Offline',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(wrap(HomeIdleView(
      online: true,
      onGoOnline: () {},
      onGoOffline: () {},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Finding orders near you…'), findsOneWidget);
    expect(find.text('Go Offline'), findsOneWidget);
  });
}
