import 'package:delivery_partner_app/shared/widgets/navigation/partner_app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the shared brand and unread notification treatment',
      (tester) async {
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

    expect(find.text('Qikzoo'), findsOneWidget);
    expect(find.text('PARTNER'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Notifications, 3 unread'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Notifications, 3 unread'));
    expect(notificationTapped, isTrue);
    expect(tester.takeException(), isNull);
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
