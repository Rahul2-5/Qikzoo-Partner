import 'package:delivery_partner_app/features/notifications/screens/notifications_screen.dart';
import 'package:delivery_partner_app/models/notifications/notification_model.dart';
import 'package:delivery_partner_app/repositories/notifications/notifications_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotificationsRepository implements NotificationsRepository {
  _FakeNotificationsRepository(this.notifications);

  final List<NotificationModel> notifications;
  final List<String> markedReadIds = [];

  @override
  Future<List<NotificationModel>> getNotifications() async => notifications;

  @override
  Future<void> markAsRead(String id) async {
    markedReadIds.add(id);
  }
}

void main() {
  testWidgets('notifications screen marks an unread notification as read', (tester) async {
    final repository = _FakeNotificationsRepository([
      NotificationModel(
        id: 'offer-1',
        title: 'New incentive available',
        body: 'Complete 5 orders to earn a bonus.',
        isRead: false,
        createdAt: DateTime.now(),
        type: NotificationType.incentiveUnlocked,
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [notificationsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('New incentive available'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);

    await tester.tap(find.text('New incentive available'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(repository.markedReadIds, ['offer-1']);
  });

  testWidgets('notifications screen renders a useful empty state', (tester) async {
    final repository = _FakeNotificationsRepository([]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [notificationsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('You are all caught up.'), findsOneWidget);
  });
}
