import 'package:delivery_partner_app/shared/widgets/navigation/partner_app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the shared brand and unread notification treatment',
      (tester) async {
    // bySemanticsLabel needs the semantics tree actually built — Flutter
    // widget tests don't generate it by default.
    final semantics = tester.ensureSemantics();
    var notificationTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: PartnerAppHeader(
              subtitle: 'Earnings overview',
              unreadNotificationCount: 3,
              onNotifications: () => notificationTapped = true,
            ),
          ),
        ),
      ),
    );

    // The brand mark is now an image (see PartnerWordmark), not literal
    // "Qikzoo"/"PARTNER" text — its Semantics label is what actually still
    // carries the brand name, for screen readers and for this test alike.
    // Like the notification button below, PartnerWordmark's Semantics
    // doesn't set `container: true`, so its label merges with the
    // descendant subtitle Text's own semantics (a trailing "\nEarnings
    // overview") rather than staying exactly "Qikzoo Partner, Earnings
    // overview".
    final wordmarkLabel =
        RegExp(r'^Qikzoo Partner, Earnings overview\nEarnings overview$');
    expect(find.bySemanticsLabel(wordmarkLabel), findsOneWidget);
    expect(find.text('Earnings overview'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // The button's Semantics doesn't set `container: true`, so its label
    // merges with the descendant unread-count Text's own semantics (a
    // trailing "\n3") rather than staying exactly "Notifications, 3 unread".
    final notificationButtonLabel = RegExp(r'^Notifications, 3 unread\n3$');
    expect(
      find.bySemanticsLabel(notificationButtonLabel),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel(notificationButtonLabel));
    expect(notificationTapped, isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('keeps the notification action at an accessible touch size',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerNotificationButton(
            unreadCount: 0,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(Ink)),
      const Size(48, 48),
    );
    expect(tester.takeException(), isNull);
  });
}
