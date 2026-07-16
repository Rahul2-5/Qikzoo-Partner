import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/dashboard/views/home_idle_view.dart';

void setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('offline state shows the offline hero', (tester) async {
    setSurface(tester, const Size(400, 1600));
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
    setSurface(tester, const Size(400, 1600));
    await tester.pumpWidget(wrap(HomeIdleView(
      online: true,
      onGoOnline: () {},
      onGoOffline: () {},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Finding orders near you…'), findsOneWidget);
    expect(find.text('Go Offline'), findsOneWidget);
  });

  testWidgets('compact dashboard stacks performance below earnings',
      (tester) async {
    setSurface(tester, const Size(400, 1000));
    await tester.pumpWidget(wrap(HomeIdleView(
      online: false,
      onGoOnline: () {},
      onGoOffline: () {},
    )));

    final earningsY = tester.getTopLeft(find.text("Today's Earnings")).dy;
    final performanceY = tester.getTopLeft(find.text("Today's performance")).dy;

    expect(performanceY, greaterThan(earningsY));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide dashboard uses a two-column workspace', (tester) async {
    setSurface(tester, const Size(1000, 900));
    await tester.pumpWidget(wrap(HomeIdleView(
      online: false,
      onGoOnline: () {},
      onGoOffline: () {},
    )));

    final earningsX = tester.getTopLeft(find.text("Today's Earnings")).dx;
    final performanceX = tester.getTopLeft(find.text("Today's performance")).dx;

    expect(performanceX, greaterThan(earningsX + 200));
    expect(tester.takeException(), isNull);
  });
}
