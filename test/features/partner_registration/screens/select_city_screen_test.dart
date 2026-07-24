import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/select_city_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp() {
  return ProviderScope(
    child: GetMaterialApp(
      initialRoute: AppRoutes.deliveryZone,
      getPages: [
        GetPage(
          name: AppRoutes.deliveryZone,
          page: SelectCityScreen.new,
        ),
      ],
    ),
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('selecting Mumbai reveals nearby location choices',
      (tester) async {
    setSurface(tester, const Size(400, 900));
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('Mumbai'));
    await tester.pumpAndSettle();

    expect(find.text('Nearby locations'), findsOneWidget);
    expect(find.text('Andheri East'), findsOneWidget);
    expect(find.text('Bandra West'), findsOneWidget);
    expect(find.text('Search nearby location'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Bandra');
    await tester.pumpAndSettle();

    expect(find.text('Bandra East'), findsOneWidget);
    expect(find.text('Bandra West'), findsOneWidget);
    expect(find.text('Andheri East'), findsNothing);
  });
}
