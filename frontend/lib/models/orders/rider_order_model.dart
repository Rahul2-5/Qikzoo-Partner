import 'package:equatable/equatable.dart';

/// Mirrors the backend's `RiderOrderStatus` enum exactly
/// (`rider-orders/logic/rider-order.transitions.ts`) — the rider's own
/// finer-grained delivery journey, independent of the parent
/// RestaurantOrder's status below.
enum RiderOrderStatus {
  assigned,
  accepted,
  arrivedAtRestaurant,
  pickedUp,
  outForDelivery,
  delivered,
  cancelled,
  unknown;

  static RiderOrderStatus fromBackend(Object? value) => switch (value) {
        'ASSIGNED' => RiderOrderStatus.assigned,
        'ACCEPTED' => RiderOrderStatus.accepted,
        'ARRIVED_AT_RESTAURANT' => RiderOrderStatus.arrivedAtRestaurant,
        'PICKED_UP' => RiderOrderStatus.pickedUp,
        'OUT_FOR_DELIVERY' => RiderOrderStatus.outForDelivery,
        'DELIVERED' => RiderOrderStatus.delivered,
        'CANCELLED' => RiderOrderStatus.cancelled,
        _ => RiderOrderStatus.unknown,
      };

  String get label => switch (this) {
        RiderOrderStatus.assigned => 'Assigned',
        RiderOrderStatus.accepted => 'Accepted',
        RiderOrderStatus.arrivedAtRestaurant => 'At restaurant',
        RiderOrderStatus.pickedUp => 'Picked up',
        RiderOrderStatus.outForDelivery => 'Out for delivery',
        RiderOrderStatus.delivered => 'Delivered',
        RiderOrderStatus.cancelled => 'Cancelled',
        RiderOrderStatus.unknown => 'Unknown',
      };

  bool get isTerminal =>
      this == RiderOrderStatus.delivered || this == RiderOrderStatus.cancelled;

  /// Mirrors `rider-order.transitions.ts`'s TRANSITIONS map exactly —
  /// every non-terminal status can transition to CANCELLED, matching
  /// `RiderOrdersService.cancel`'s own guard, so the app never offers a
  /// Cancel action the backend would reject.
  bool get canCancel => !isTerminal;
}

/// Mirrors the backend's `OrderStatus` enum (`prisma/schema.prisma`) — the
/// canonical RestaurantOrder lifecycle, richer than [RiderOrderStatus]
/// because it also covers the pre-dispatch kitchen stages.
enum RestaurantOrderStatus {
  newOrder,
  accepted,
  preparing,
  readyForPickup,
  handedToRider,
  pickedUp,
  delivered,
  rejected,
  cancelled,
  failed,
  refunded,
  unknown;

  static RestaurantOrderStatus fromBackend(Object? value) => switch (value) {
        'NEW' => RestaurantOrderStatus.newOrder,
        'ACCEPTED' => RestaurantOrderStatus.accepted,
        'PREPARING' => RestaurantOrderStatus.preparing,
        'READY_FOR_PICKUP' => RestaurantOrderStatus.readyForPickup,
        'HANDED_TO_RIDER' => RestaurantOrderStatus.handedToRider,
        'PICKED_UP' => RestaurantOrderStatus.pickedUp,
        'DELIVERED' => RestaurantOrderStatus.delivered,
        'REJECTED' => RestaurantOrderStatus.rejected,
        'CANCELLED' => RestaurantOrderStatus.cancelled,
        'FAILED' => RestaurantOrderStatus.failed,
        'REFUNDED' => RestaurantOrderStatus.refunded,
        _ => RestaurantOrderStatus.unknown,
      };

  String get label => switch (this) {
        RestaurantOrderStatus.newOrder => 'New',
        RestaurantOrderStatus.accepted => 'Accepted',
        RestaurantOrderStatus.preparing => 'Preparing',
        RestaurantOrderStatus.readyForPickup => 'Ready for pickup',
        RestaurantOrderStatus.handedToRider => 'Handed to rider',
        RestaurantOrderStatus.pickedUp => 'Picked up',
        RestaurantOrderStatus.delivered => 'Delivered',
        RestaurantOrderStatus.rejected => 'Rejected',
        RestaurantOrderStatus.cancelled => 'Cancelled',
        RestaurantOrderStatus.failed => 'Failed',
        RestaurantOrderStatus.refunded => 'Refunded',
        RestaurantOrderStatus.unknown => 'Unknown',
      };
}

/// Mirrors the backend's `PickupQrStatus` enum.
enum PickupQrStatus {
  active,
  used,
  expired,
  unknown;

  static PickupQrStatus fromBackend(Object? value) => switch (value) {
        'ACTIVE' => PickupQrStatus.active,
        'USED' => PickupQrStatus.used,
        'EXPIRED' => PickupQrStatus.expired,
        _ => PickupQrStatus.unknown,
      };
}

/// Mirrors the backend's `DeliveryOtpStatus` enum.
enum DeliveryOtpStatus {
  active,
  verified,
  expired,
  unknown;

  static DeliveryOtpStatus fromBackend(Object? value) => switch (value) {
        'ACTIVE' => DeliveryOtpStatus.active,
        'VERIFIED' => DeliveryOtpStatus.verified,
        'EXPIRED' => DeliveryOtpStatus.expired,
        _ => DeliveryOtpStatus.unknown,
      };
}

/// The restaurant's pickup contact/location — from `RiderOrdersService`'s
/// `restaurant` field (branch phone/address/landmark/coordinates + the
/// parent Restaurant's display name).
class RestaurantContactModel extends Equatable {
  final String? name;
  final String phone;
  final String address;
  final String? landmark;
  final double latitude;
  final double longitude;

  const RestaurantContactModel({
    required this.name,
    required this.phone,
    required this.address,
    required this.landmark,
    required this.latitude,
    required this.longitude,
  });

  factory RestaurantContactModel.fromJson(Map<String, dynamic> json) {
    return RestaurantContactModel(
      name: _str(json['name']),
      phone: json['phone'] is String ? json['phone'] as String : '',
      address: json['address'] is String ? json['address'] as String : '',
      landmark: _str(json['landmark']),
      latitude: _num(json['latitude']),
      longitude: _num(json['longitude']),
    );
  }

  @override
  List<Object?> get props => [name, phone, address, landmark, latitude, longitude];
}

/// One row of the RestaurantOrder's status timeline — only present on the
/// single-order detail response (`GET /rider/orders/:id`).
class OrderStatusHistoryEntry extends Equatable {
  final RestaurantOrderStatus fromStatus;
  final RestaurantOrderStatus toStatus;
  final String? reason;
  final DateTime changedAt;

  const OrderStatusHistoryEntry({
    required this.fromStatus,
    required this.toStatus,
    required this.reason,
    required this.changedAt,
  });

  factory OrderStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryEntry(
      fromStatus: RestaurantOrderStatus.fromBackend(json['fromStatus']),
      toStatus: RestaurantOrderStatus.fromBackend(json['toStatus']),
      reason: _str(json['reason']),
      changedAt: _date(json['changedAt']) ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [fromStatus, toStatus, reason, changedAt];
}

/// The restaurant-generated secure pickup token's status — the rider's app
/// never sees the token itself, only whether one is active to scan.
class PickupQrInfo extends Equatable {
  final PickupQrStatus status;
  final DateTime expiresAt;

  const PickupQrInfo({required this.status, required this.expiresAt});

  factory PickupQrInfo.fromJson(Map<String, dynamic> json) => PickupQrInfo(
        status: PickupQrStatus.fromBackend(json['status']),
        expiresAt: _date(json['expiresAt']) ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [status, expiresAt];
}

/// The customer-facing delivery OTP's status/attempt-budget — the rider
/// never sees the code itself (it's SMS'd to the customer); only how many
/// attempts remain matters to the app.
class DeliveryOtpInfo extends Equatable {
  final DeliveryOtpStatus status;
  final int attempts;
  final int maxAttempts;
  final DateTime expiresAt;

  const DeliveryOtpInfo({
    required this.status,
    required this.attempts,
    required this.maxAttempts,
    required this.expiresAt,
  });

  int get attemptsRemaining => (maxAttempts - attempts).clamp(0, maxAttempts);

  factory DeliveryOtpInfo.fromJson(Map<String, dynamic> json) => DeliveryOtpInfo(
        status: DeliveryOtpStatus.fromBackend(json['status']),
        attempts: _int(json['attempts']),
        maxAttempts: _int(json['maxAttempts']) == 0 ? 5 : _int(json['maxAttempts']),
        expiresAt: _date(json['expiresAt']) ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [status, attempts, maxAttempts, expiresAt];
}

/// The RestaurantOrder fields the rider app actually needs — a subset of
/// `RiderOrderResponse['order']`. `customerPhone` is nullable exactly
/// because the backend redacts it until the rider has reached the
/// restaurant (`hasArrivedAtRestaurant` gate) — never fall back to a
/// placeholder value here, `null` must render as "not yet available".
class RestaurantOrderSummary extends Equatable {
  final String id;
  final String orderNumber;
  final String customerName;
  final String? customerPhone;
  final String? deliveryAddressLine;
  final String? deliveryCity;
  final String? deliveryPincode;
  final double? deliveryLat;
  final double? deliveryLng;
  final int totalPaise;
  final String? customerNote;
  final RestaurantOrderStatus status;

  /// Only populated on the detail response (`GET /rider/orders/:id`) —
  /// `null` (not empty) on `current`/`history` list items, since the
  /// backend simply doesn't include it there.
  final List<OrderStatusHistoryEntry>? statusHistory;

  const RestaurantOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddressLine,
    required this.deliveryCity,
    required this.deliveryPincode,
    required this.deliveryLat,
    required this.deliveryLng,
    required this.totalPaise,
    required this.customerNote,
    required this.status,
    required this.statusHistory,
  });

  factory RestaurantOrderSummary.fromJson(Map<String, dynamic> json) {
    final historyJson = json['statusHistory'];
    return RestaurantOrderSummary(
      id: json['id'] is String ? json['id'] as String : '',
      orderNumber: _str(json['orderNumber']) ?? '',
      customerName: _str(json['customerName']) ?? '',
      customerPhone: _str(json['customerPhone']),
      deliveryAddressLine: _str(json['deliveryAddressLine']),
      deliveryCity: _str(json['deliveryCity']),
      deliveryPincode: _str(json['deliveryPincode']),
      deliveryLat: json['deliveryLat'] == null ? null : _num(json['deliveryLat']),
      deliveryLng: json['deliveryLng'] == null ? null : _num(json['deliveryLng']),
      totalPaise: _int(json['totalPaise']),
      customerNote: _str(json['customerNote']),
      status: RestaurantOrderStatus.fromBackend(json['status']),
      statusHistory: historyJson is List
          ? historyJson
              .whereType<Map<String, dynamic>>()
              .map(OrderStatusHistoryEntry.fromJson)
              .toList()
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        customerName,
        customerPhone,
        deliveryAddressLine,
        deliveryCity,
        deliveryPincode,
        deliveryLat,
        deliveryLng,
        totalPaise,
        customerNote,
        status,
        statusHistory,
      ];
}

/// The rider-facing RiderOrder response — from `GET /rider/orders/current`,
/// `GET /rider/orders/:id` and `GET /rider/orders/history`
/// (`RiderOrdersService.toRiderOrderResponse`'s exact shape).
class RiderOrderModel extends Equatable {
  final String id;
  final String orderId;
  final RiderOrderStatus status;
  final double? distanceKm;
  final int earningsPaise;
  final int tipsPaise;
  final double? etaMinutes;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? pickedUpAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final RestaurantContactModel restaurant;
  final RestaurantOrderSummary order;
  final PickupQrInfo? pickupQr;
  final DeliveryOtpInfo? deliveryOtp;

  const RiderOrderModel({
    required this.id,
    required this.orderId,
    required this.status,
    required this.distanceKm,
    required this.earningsPaise,
    required this.tipsPaise,
    required this.etaMinutes,
    required this.assignedAt,
    required this.acceptedAt,
    required this.arrivedAt,
    required this.pickedUpAt,
    required this.outForDeliveryAt,
    required this.deliveredAt,
    required this.cancelledAt,
    required this.cancellationReason,
    required this.restaurant,
    required this.order,
    required this.pickupQr,
    required this.deliveryOtp,
  });

  factory RiderOrderModel.fromJson(Map<String, dynamic> json) {
    final restaurantJson = json['restaurant'];
    final orderJson = json['order'];
    final pickupQrJson = json['pickupQr'];
    final deliveryOtpJson = json['deliveryOtp'];
    return RiderOrderModel(
      id: json['id'] is String ? json['id'] as String : '',
      orderId: _str(json['orderId']) ?? '',
      status: RiderOrderStatus.fromBackend(json['status']),
      distanceKm: json['distanceKm'] == null ? null : _num(json['distanceKm']),
      earningsPaise: _int(json['earningsPaise']),
      tipsPaise: _int(json['tipsPaise']),
      etaMinutes: json['etaMinutes'] == null ? null : _num(json['etaMinutes']),
      assignedAt: _date(json['assignedAt']) ?? DateTime.now(),
      acceptedAt: _date(json['acceptedAt']),
      arrivedAt: _date(json['arrivedAt']),
      pickedUpAt: _date(json['pickedUpAt']),
      outForDeliveryAt: _date(json['outForDeliveryAt']),
      deliveredAt: _date(json['deliveredAt']),
      cancelledAt: _date(json['cancelledAt']),
      cancellationReason: _str(json['cancellationReason']),
      restaurant: restaurantJson is Map<String, dynamic>
          ? RestaurantContactModel.fromJson(restaurantJson)
          : const RestaurantContactModel(
              name: null,
              phone: '',
              address: '',
              landmark: null,
              latitude: 0,
              longitude: 0,
            ),
      order: orderJson is Map<String, dynamic>
          ? RestaurantOrderSummary.fromJson(orderJson)
          : RestaurantOrderSummary.fromJson(const {}),
      pickupQr:
          pickupQrJson is Map<String, dynamic> ? PickupQrInfo.fromJson(pickupQrJson) : null,
      deliveryOtp: deliveryOtpJson is Map<String, dynamic>
          ? DeliveryOtpInfo.fromJson(deliveryOtpJson)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        status,
        distanceKm,
        earningsPaise,
        tipsPaise,
        etaMinutes,
        assignedAt,
        acceptedAt,
        arrivedAt,
        pickedUpAt,
        outForDeliveryAt,
        deliveredAt,
        cancelledAt,
        cancellationReason,
        restaurant,
        order,
        pickupQr,
        deliveryOtp,
      ];
}

String? _str(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

double _num(Object? value) {
  if (value is num) return value.toDouble();
  return 0;
}

DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value) : null;
