import 'package:equatable/equatable.dart';

enum NotificationType {
  newOrder,
  orderCancelled,
  addressUpdated,
  incentiveUnlocked,
  paymentCredited,
  accountUpdate,
  system,
}

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
    final event = (json['event'] is String ? json['event'] as String : '').toLowerCase();
    final data = json['data'];
    final dataType = (data is Map && data['type'] is String
            ? data['type'] as String
            : '')
        .toUpperCase();
    final title = json['subject'] is String ? json['subject'] as String : 'Update';
    final body = json['message'] is String ? json['message'] as String : '';

    return NotificationModel(
      id: json['id'] is String ? json['id'] as String : '',
      title: title,
      body: body,
      isRead: json['readAt'] != null,
      createdAt:
          DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      type: _typeFor(event, dataType, title, body),
    );
  }

  static NotificationType _typeFor(
    String event,
    String dataType,
    String title,
    String body,
  ) {
    final text = '$event $dataType $title $body'.toLowerCase();

    if (text.contains('cancel')) {
      return NotificationType.orderCancelled;
    }
    if (text.contains('address') || text.contains('location')) {
      return NotificationType.addressUpdated;
    }
    if (text.contains('incentive') || text.contains('bonus') || text.contains('reward') || text.contains('unlocked')) {
      return NotificationType.incentiveUnlocked;
    }
    if (text.contains('earning') || text.contains('payout') || text.contains('payment') || text.contains('credit') || text.contains('settled')) {
      return NotificationType.paymentCredited;
    }
    if (text.contains('kyc') || text.contains('document') || text.contains('account') || text.contains('verification') || text.contains('profile')) {
      return NotificationType.accountUpdate;
    }
    if (event.startsWith('dispatch.') ||
        event.startsWith('rider_order.') ||
        dataType == 'NEW_DELIVERY_OFFER' ||
        text.contains('order') ||
        text.contains('delivery')) {
      return NotificationType.newOrder;
    }

    return NotificationType.system;
  }

  @override
  List<Object?> get props => [id, title, body, isRead, createdAt, type];
}
