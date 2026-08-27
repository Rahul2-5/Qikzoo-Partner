import 'dart:math' as math;

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

/// Mirrors the backend's `PickupOtpStatus` enum.
enum PickupOtpStatus {
  active,
  verified,
  expired,
  unknown;

  static PickupOtpStatus fromBackend(Object? value) => switch (value) {
        'ACTIVE' => PickupOtpStatus.active,
        'VERIFIED' => PickupOtpStatus.verified,
        'EXPIRED' => PickupOtpStatus.expired,
        _ => PickupOtpStatus.unknown,
      };
}

enum OrderPaymentMethod {
  cod,
  online,
  unknown;

  static OrderPaymentMethod fromBackend(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    if (normalized == 'COD') return OrderPaymentMethod.cod;
    if (normalized == null || normalized.isEmpty) {
      return OrderPaymentMethod.unknown;
    }
    // Gateway selection belongs to the backend. Every non-COD method is
    // presented to the rider as online payment, including future providers.
    return OrderPaymentMethod.online;
  }
}

enum OrderPaymentStatus {
  pending,
  paid,
  failed,
  refunded,
  refundPending,
  refundFailed,
  unknown;

  static OrderPaymentStatus fromBackend(Object? value) =>
      switch (value?.toString().trim().toUpperCase()) {
        'PENDING' => OrderPaymentStatus.pending,
        'PAID' => OrderPaymentStatus.paid,
        'FAILED' => OrderPaymentStatus.failed,
        'REFUNDED' => OrderPaymentStatus.refunded,
        'REFUND_PENDING' => OrderPaymentStatus.refundPending,
        'REFUND_FAILED' => OrderPaymentStatus.refundFailed,
        _ => OrderPaymentStatus.unknown,
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
  List<Object?> get props =>
      [name, phone, address, landmark, latitude, longitude];
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

/// The restaurant-visible, restaurant-verified pickup OTP's status — the
/// rider never enters, submits, or generates this code, they only ever
/// read it (passively, once GPS-validated arrival unlocks [code]) so the
/// restaurant staff can type/confirm it on their own dashboard.
class PickupOtpInfo extends Equatable {
  final String? code;
  final PickupOtpStatus status;
  final DateTime expiresAt;

  const PickupOtpInfo({
    required this.code,
    required this.status,
    required this.expiresAt,
  });

  factory PickupOtpInfo.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final code = _str(json['code'] ??
          json['otp'] ??
          json['pickupOtp'] ??
          json['otpCode'] ??
          json['value'] ??
          json['pickupCode']);
      return PickupOtpInfo(
        code: code,
        status: PickupOtpStatus.fromBackend(json['status']),
        expiresAt: _date(json['expiresAt'] ?? json['expires_at']) ??
            DateTime.now().add(const Duration(minutes: 15)),
      );
    }
    if (json is String && json.trim().isNotEmpty) {
      return PickupOtpInfo(
        code: json.trim(),
        status: PickupOtpStatus.active,
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );
    }
    if (json is num) {
      return PickupOtpInfo(
        code: json.toString(),
        status: PickupOtpStatus.active,
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );
    }
    return PickupOtpInfo(
      code: null,
      status: PickupOtpStatus.unknown,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
  }

  @override
  List<Object?> get props => [code, status, expiresAt];
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
  final OrderPaymentMethod paymentMethod;
  final OrderPaymentStatus paymentStatus;
  final DateTime? paidAt;
  final String? paymentReference;
  final String? collectionSource;
  final String? customerNote;
  final RestaurantOrderStatus status;

  /// Only populated on the detail response (`GET /rider/orders/:id`) —
  /// `null` (not empty) on `current`/`history` list items, since the
  /// backend simply doesn't include it there.
  final List<OrderStatusHistoryEntry>? statusHistory;

  /// `null` until the rider has arrived at the restaurant; even once
  /// present, `pickupOtp.code` itself stays `null` until server-side GPS
  /// validation on `POST /rider/orders/:id/arrived` succeeds — the rider
  /// never types this code, only reads it once it appears.
  final PickupOtpInfo? pickupOtp;

  /// List of items ordered by the customer (for pickup verification)
  final List<OrderItemModel> items;

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
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paidAt,
    required this.paymentReference,
    required this.collectionSource,
    required this.customerNote,
    required this.status,
    required this.statusHistory,
    required this.pickupOtp,
    this.items = const [],
  });

  bool get isPaid => paymentStatus == OrderPaymentStatus.paid;

  bool get isPaidOnline => paymentMethod == OrderPaymentMethod.online && isPaid;

  bool get cashCollectionRequired =>
      paymentMethod == OrderPaymentMethod.cod && !isPaid;

  bool get isPaidCod => paymentMethod == OrderPaymentMethod.cod && isPaid;

  factory RestaurantOrderSummary.fromJson(Map<String, dynamic> json,
      {dynamic pickupOtpRaw}) {
    final historyJson = json['statusHistory'];
    final rawOtp = pickupOtpRaw ??
        json['pickupOtp'] ??
        json['pickup_otp'] ??
        json['pickupOtpCode'] ??
        json['pickupCode'] ??
        json['otp'];
    PickupOtpInfo? pickupOtp;
    if (rawOtp != null) {
      pickupOtp = PickupOtpInfo.fromJson(rawOtp);
    }
    final itemsJson = json['items'] ?? json['orderItems'] ?? json['itemList'];
    final itemsList = itemsJson is List
        ? itemsJson
            .whereType<Map<String, dynamic>>()
            .map(OrderItemModel.fromJson)
            .toList()
        : const <OrderItemModel>[];
    return RestaurantOrderSummary(
      id: json['id'] is String ? json['id'] as String : '',
      orderNumber: _str(json['orderNumber']) ?? '',
      customerName: _str(json['customerName']) ?? '',
      customerPhone: _str(json['customerPhone']),
      deliveryAddressLine: _str(json['deliveryAddressLine']),
      deliveryCity: _str(json['deliveryCity']),
      deliveryPincode: _str(json['deliveryPincode']),
      deliveryLat:
          json['deliveryLat'] == null ? null : _num(json['deliveryLat']),
      deliveryLng:
          json['deliveryLng'] == null ? null : _num(json['deliveryLng']),
      totalPaise: _int(json['totalPaise']),
      paymentMethod: OrderPaymentMethod.fromBackend(json['paymentMethod']),
      paymentStatus: OrderPaymentStatus.fromBackend(json['paymentStatus']),
      paidAt: _date(json['paidAt'] ?? json['paid_at']),
      paymentReference: _str(
        json['paymentReference'] ??
            json['transactionId'] ??
            (json['paymentAttempt'] is Map<String, dynamic>
                ? (json['paymentAttempt']
                    as Map<String, dynamic>)['transactionId']
                : null),
      ),
      collectionSource: _str(json['collectionSource']),
      customerNote: _str(json['customerNote']),
      status: RestaurantOrderStatus.fromBackend(json['status']),
      statusHistory: historyJson is List
          ? historyJson
              .whereType<Map<String, dynamic>>()
              .map(OrderStatusHistoryEntry.fromJson)
              .toList()
          : null,
      pickupOtp: pickupOtp,
      items: itemsList,
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
        paymentMethod,
        paymentStatus,
        paidAt,
        paymentReference,
        collectionSource,
        customerNote,
        status,
        statusHistory,
        pickupOtp,
        items,
      ];
}

class OrderItemModel extends Equatable {
  final String name;
  final int quantity;
  final double? price;
  final bool isVeg;
  final String? instructions;

  const OrderItemModel({
    required this.name,
    required this.quantity,
    this.price,
    this.isVeg = true,
    this.instructions,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      name: (json['name'] ??
              json['nameSnapshot'] ??
              json['itemName'] ??
              json['title'] ??
              'Item')
          .toString(),
      quantity: json['quantity'] is num
          ? (json['quantity'] as num).toInt()
          : (json['qty'] is num ? (json['qty'] as num).toInt() : 1),
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : json['pricePaise'] is num
              ? (json['pricePaise'] as num) / 100.0
              : json['unitPricePaise'] is num
                  ? (json['unitPricePaise'] as num) / 100.0
                  : null,
      isVeg: json['isVeg'] == true ||
          json['is_veg'] == true ||
          json['foodType'] == 'VEG' ||
          json['foodTypeSnapshot'] == 'VEG' ||
          json['itemType'] == 'VEG',
      instructions: _str(
        json['instructions'] ?? json['itemNote'] ?? json['specialInstructions'],
      ),
    );
  }

  @override
  List<Object?> get props => [name, quantity, price, isVeg, instructions];
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
  });

  /// The Pickup Verification OTP to show to restaurant staff.
  String get displayPickupOtp {
    if (order.pickupOtp?.code != null &&
        order.pickupOtp!.code!.trim().isNotEmpty) {
      return order.pickupOtp!.code!.trim();
    }
    final cleanNum = order.orderNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNum.length >= 4) {
      return cleanNum.substring(cleanNum.length - 4);
    }
    final cleanId = id.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanId.length >= 4) {
      return cleanId.substring(cleanId.length - 4);
    }
    return (id.hashCode.abs() % 9000 + 1000).toString();
  }

  factory RiderOrderModel.fromJson(Map<String, dynamic> json) {
    final restaurantJson = json['restaurant'] is Map<String, dynamic>
        ? json['restaurant'] as Map<String, dynamic>
        : null;
    final orderJson = json['order'] is Map<String, dynamic>
        ? json['order'] as Map<String, dynamic>
        : null;

    final restaurant = restaurantJson != null
        ? RestaurantContactModel.fromJson(restaurantJson)
        : const RestaurantContactModel(
            name: null,
            phone: '',
            address: '',
            landmark: null,
            latitude: 0,
            longitude: 0,
          );

    final pickupOtpRaw = orderJson?['pickupOtp'] ??
        orderJson?['pickup_otp'] ??
        orderJson?['pickupOtpCode'] ??
        orderJson?['pickupCode'] ??
        orderJson?['otp'] ??
        json['pickupOtp'] ??
        json['pickup_otp'] ??
        json['pickupOtpCode'] ??
        json['pickupCode'] ??
        json['otp'] ??
        json['code'];

    final order = orderJson != null
        ? RestaurantOrderSummary.fromJson(orderJson, pickupOtpRaw: pickupOtpRaw)
        : RestaurantOrderSummary.fromJson(const {}, pickupOtpRaw: pickupOtpRaw);

    final earningsPaise = _parseEarningsPaise(json, orderJson);
    final tipsPaise = _parseTipsPaise(json, orderJson);
    final distanceKm = _parseDistanceKm(json, orderJson, restaurant, order);

    return RiderOrderModel(
      id: json['id'] is String ? json['id'] as String : '',
      orderId: _str(json['orderId']) ?? '',
      status: RiderOrderStatus.fromBackend(json['status']),
      distanceKm: distanceKm,
      earningsPaise: earningsPaise,
      tipsPaise: tipsPaise,
      etaMinutes: json['etaMinutes'] == null ? null : _num(json['etaMinutes']),
      assignedAt: _date(json['assignedAt']) ?? DateTime.now(),
      acceptedAt: _date(json['acceptedAt']),
      arrivedAt: _date(json['arrivedAt']),
      pickedUpAt: _date(json['pickedUpAt']),
      outForDeliveryAt: _date(json['outForDeliveryAt']),
      deliveredAt: _date(json['deliveredAt']),
      cancelledAt: _date(json['cancelledAt']),
      cancellationReason: _str(json['cancellationReason']),
      restaurant: restaurant,
      order: order,
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
      ];
}

int _parseEarningsPaise(
    Map<String, dynamic> json, Map<String, dynamic>? orderJson) {
  // Check direct paise fields
  for (final key in [
    'earningsPaise',
    'payoutPaise',
    'deliveryFeePaise',
    'riderEarningsPaise',
    'estimatedEarningsPaise',
    'totalEarningPaise',
  ]) {
    final v = json[key] ?? orderJson?[key];
    if (v != null) {
      final val = _int(v);
      if (val > 0) return val;
    }
  }

  // Check rupee fields (need * 100)
  for (final key in [
    'earnings',
    'payout',
    'deliveryFee',
    'deliveryEarning',
    'riderEarnings',
    'riderFee',
    'estimatedEarnings',
    'earningAmount',
    'fee',
  ]) {
    final v = json[key] ?? orderJson?[key];
    if (v != null) {
      final val = _num(v);
      if (val > 0) return (val * 100).round();
    }
  }

  return 0;
}

int _parseTipsPaise(
    Map<String, dynamic> json, Map<String, dynamic>? orderJson) {
  for (final key in ['tipsPaise', 'tipPaise', 'riderTipPaise']) {
    final v = json[key] ?? orderJson?[key];
    if (v != null) {
      final val = _int(v);
      if (val > 0) return val;
    }
  }

  for (final key in ['tips', 'tip', 'riderTip']) {
    final v = json[key] ?? orderJson?[key];
    if (v != null) {
      final val = _num(v);
      if (val > 0) return (val * 100).round();
    }
  }

  return 0;
}

double? _parseDistanceKm(
  Map<String, dynamic> json,
  Map<String, dynamic>? orderJson,
  RestaurantContactModel restaurant,
  RestaurantOrderSummary order,
) {
  for (final key in [
    'distanceKm',
    'distance',
    'totalDistanceKm',
    'totalDistance',
    'tripDistance',
    'tripDistanceKm',
  ]) {
    final v = json[key] ?? orderJson?[key];
    if (v != null) {
      final val = _num(v);
      if (val > 0) return val;
    }
  }

  // Fallback: Geodesic distance from restaurant coordinates to customer coordinates
  final lat1 = restaurant.latitude;
  final lon1 = restaurant.longitude;
  final lat2 = order.deliveryLat;
  final lon2 = order.deliveryLng;

  if (lat1 != 0 &&
      lon1 != 0 &&
      lat2 != null &&
      lon2 != null &&
      lat2 != 0 &&
      lon2 != 0) {
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    final dist = 12742 * math.asin(math.sqrt(a));
    if (dist > 0.05) {
      return double.parse(dist.toStringAsFixed(1));
    }
  }

  return null;
}

String? _str(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final n = num.tryParse(value);
    if (n != null) return n.toInt();
  }
  return 0;
}

double _num(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final d = double.tryParse(value);
    if (d != null) return d;
  }
  return 0;
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
