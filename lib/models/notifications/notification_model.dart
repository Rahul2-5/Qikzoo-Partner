import 'package:equatable/equatable.dart';

enum NotificationType { order, earnings, system, promotion }

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final NotificationType type;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.type,
  });

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        type: type,
      );

  /// Maps a raw `NotificationLog` row (`GET /rider/notifications`) — the
  /// Prisma model's user-facing copy lives in `subject`/`message`, and it
  /// has no `type` field, only `event` (e.g. `dispatch.new_assignment`) and
  /// a `data.type` (e.g. `NEW_DELIVERY_OFFER`), so this infers the UI-only
  /// [NotificationType] from those instead of inventing a new backend field.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final event = json['event'] is String ? json['event'] as String : '';
    final data = json['data'];
    final dataType =
        data is Map && data['type'] is String ? data['type'] as String : '';
    return NotificationModel(
      id: json['id'] is String ? json['id'] as String : '',
      title: json['subject'] is String ? json['subject'] as String : 'Update',
      body: json['message'] is String ? json['message'] as String : '',
      isRead: json['readAt'] != null,
      createdAt:
          DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      type: _typeFor(event, dataType),
    );
  }

  static NotificationType _typeFor(String event, String dataType) {
    if (event.startsWith('dispatch.') ||
        event.startsWith('rider_order.') ||
        dataType == 'NEW_DELIVERY_OFFER') {
      return NotificationType.order;
    }
    if (event.contains('earning') || event.contains('payout')) {
      return NotificationType.earnings;
    }
    if (event.contains('promo') || event.contains('incentive')) {
      return NotificationType.promotion;
    }
    return NotificationType.system;
  }

  @override
  List<Object?> get props => [id, title, body, isRead, createdAt, type];
}
