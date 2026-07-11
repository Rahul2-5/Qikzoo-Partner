import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/notifications/notifications_repository.dart';
import '../../models/notifications/notification_model.dart';

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() =>
      ref.watch(notificationsRepositoryProvider).getNotifications();

  Future<void> markAsRead(String id) async {
    await ref.read(notificationsRepositoryProvider).markAsRead(id);
    state = AsyncData([
      for (final n in state.value ?? [])
        if (n.id == id) n.copyWith(isRead: true) else n,
    ]);
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);
