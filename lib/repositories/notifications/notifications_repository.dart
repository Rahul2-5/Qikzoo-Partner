import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/notifications/notification_model.dart';
import '../../providers/core/api_providers.dart';

abstract class NotificationsRepository {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
}

/// Backed by the rider notification inbox (`RiderNotificationInboxController`
/// / `NotificationInboxService`) — the same `NotificationLog` rows created
/// whenever `DeviceTokensService.notifyUser` fires a push. Not a separate
/// notification system; this is the only place the rider app reads that
/// history from.
class DioNotificationsRepository implements NotificationsRepository {
  const DioNotificationsRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiClient
        .get<Map<String, dynamic>>(ApiEndpoints.riderNotifications);
    final payload = _unwrap(response.data);
    final items = payload['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    await _apiClient.patch<void>(ApiEndpoints.riderNotificationRead(id));
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    if (body == null) return const {};
    final nested = body['data'];
    return nested is Map<String, dynamic> ? nested : body;
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) =>
      DioNotificationsRepository(apiClient: ref.watch(apiClientProvider)),
);
