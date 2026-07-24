import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/notifications/notification_model.dart';

abstract class NotificationsRepository {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
}

class MockNotificationsRepository implements NotificationsRepository {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: 'n1',
      title: 'New incentive available',
      body: 'Complete 5 more orders today to earn a bonus.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      type: NotificationType.promotion,
    ),
  ];

  @override
  Future<List<NotificationModel>> getNotifications() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return _notifications;
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }
}

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) => MockNotificationsRepository());
