import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/orders/widgets/order_filter_sheet.dart';
import 'package:delivery_partner_app/models/orders/order_list_entry.dart';

void main() {
  testWidgets('selecting Highest earning and Apply returns it', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    OrdersFilterResult? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await OrderFilterSheet.show(
                  context,
                  sort: OrdersSort.newest,
                  dateFilter: OrdersDateFilter.all,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Highest earning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.sort, OrdersSort.highestEarning);
    expect(result!.dateFilter, OrdersDateFilter.all);
  });
}
