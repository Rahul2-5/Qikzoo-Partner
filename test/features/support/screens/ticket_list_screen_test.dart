import 'package:delivery_partner_app/features/support/screens/ticket_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('shows the honest empty state, not fabricated tickets',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: TicketListScreen()));
    await tester.pumpAndSettle();

    // Regression guard: this screen used to seed 3 fabricated tickets
    // (TCK-1002/TCK-0985/TCK-0961) with invented outlet names and dates.
    // There is no ticketing backend yet, so a real rider must see the
    // screen's own honest empty state instead of invented history.
    expect(find.text('No tickets found'), findsOneWidget);
    expect(find.textContaining('TCK-'), findsNothing);
    expect(find.text('Noodle House, Mumbai'), findsNothing);
  });
}
