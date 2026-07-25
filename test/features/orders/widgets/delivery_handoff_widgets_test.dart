import 'package:delivery_partner_app/core/theme/app_theme.dart';
import 'package:delivery_partner_app/features/orders/widgets/delivery_handoff_card.dart';
import 'package:delivery_partner_app/features/orders/widgets/no_response_sheet.dart';
import 'package:delivery_partner_app/features/orders/widgets/quick_message_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SafeArea(child: SingleChildScrollView(child: child)),
          ),
        ),
      );

  Future<void> settleSheet(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('handoff card exposes instructions and rider actions', (tester) async {
    var quickMessageTapped = false;
    var noResponseTapped = false;

    await pumpPage(
      tester,
      DeliveryHandoffCard(
        preference: 'Call on arrival',
        buildingSummary: 'Tower B · Gate 2',
        instruction: 'Please hand over to security if unavailable.',
        onQuickMessage: () => quickMessageTapped = true,
        onNoResponse: () => noResponseTapped = true,
      ),
    );

    expect(find.text('Delivery instructions'), findsOneWidget);
    expect(find.text('Call on arrival'), findsOneWidget);
    expect(find.text('Tower B · Gate 2'), findsOneWidget);

    await tester.tap(find.text('Building access notes'));
    await settleSheet(tester);
    expect(find.textContaining('Use Gate 2 beside the pharmacy'), findsOneWidget);

    await tester.tap(find.text('Quick message'));
    expect(quickMessageTapped, isTrue);
    await tester.tap(find.text('Customer not responding?'));
    expect(noResponseTapped, isTrue);
  });

  testWidgets('quick-message sheet switches language and returns the selected message',
      (tester) async {
    String? selectedMessage;

    await pumpPage(
      tester,
      Builder(
        builder: (context) => FilledButton(
          onPressed: () async => selectedMessage = await QuickMessageSheet.show(context),
          child: const Text('Open messages'),
        ),
      ),
    );

    await tester.tap(find.text('Open messages'));
    await settleSheet(tester);
    await tester.tap(find.text('हिन्दी'));
    await tester.pump();
    expect(find.text('मैं गेट पर हूँ'), findsOneWidget);

    await tester.tap(find.text('मैं गेट पर हूँ'));
    await settleSheet(tester);
    expect(selectedMessage, 'मैं गेट पर हूँ');
  });

  testWidgets('no-response sheet enables photo proof after its local wait ends',
      (tester) async {
    NoResponseOutcome? outcome;

    await pumpPage(
      tester,
      Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            outcome = await NoResponseSheet.show(context, waitDuration: Duration.zero);
          },
          child: const Text('Open no response'),
        ),
      ),
    );

    await tester.tap(find.text('Open no response'));
    await settleSheet(tester);
    expect(find.text('You can now record contactless proof.'), findsOneWidget);

    await tester.tap(find.text('Capture drop-off photo'));
    await settleSheet(tester);
    expect(outcome, NoResponseOutcome.captureProof);
  });
}
