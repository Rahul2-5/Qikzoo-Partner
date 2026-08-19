import 'package:equatable/equatable.dart';

/// Mirrors the backend's `DispatchAttemptStatus` enum
/// (`dispatch-engine/logic/dispatch.transitions.ts`).
enum DispatchAttemptStatus {
  waitingRider,
  accepted,
  rejected,
  expired,
  cancelled,
  unknown;

  static DispatchAttemptStatus fromBackend(Object? value) => switch (value) {
        'WAITING_RIDER' => DispatchAttemptStatus.waitingRider,
        'ACCEPTED' => DispatchAttemptStatus.accepted,
        'REJECTED' => DispatchAttemptStatus.rejected,
        'EXPIRED' => DispatchAttemptStatus.expired,
        'CANCELLED' => DispatchAttemptStatus.cancelled,
        _ => DispatchAttemptStatus.unknown,
      };
}

/// A pending dispatch offer, as returned by `GET /rider/dispatch/current`
/// (`DispatchEngineService.getCurrentOffer`) — already joins in the
/// restaurant/customer/pickup/drop details and a computed payout, not just
/// the bare `DispatchAttempt` row.
class DispatchOfferModel extends Equatable {
  final String id;
  final String jobId;
  final int attemptNumber;
  final DispatchAttemptStatus status;
  final double distanceKm;
  final double? searchRadiusKm;
  final bool broadcast;
  final DateTime offeredAt;
  final DateTime expiresAt;
  final double payout;
  final String restaurantName;
  final String restaurantAddress;
  final String customerName;
  final String userAddress;
  final double dropDistanceKm;

  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;

  const DispatchOfferModel({
    required this.id,
    required this.jobId,
    required this.attemptNumber,
    required this.status,
    required this.distanceKm,
    required this.searchRadiusKm,
    required this.broadcast,
    required this.offeredAt,
    required this.expiresAt,
    required this.payout,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.customerName,
    required this.userAddress,
    required this.dropDistanceKm,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
  });

  Duration get remaining {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isExpired => remaining == Duration.zero;

  factory DispatchOfferModel.fromJson(Map<String, dynamic> json) {
    // 1. Parse offeredAt & expiresAt (handling ISO string, epoch ms, or expiresInSeconds)
    final offeredAt = _parseDateTime(json['offeredAt']) ?? DateTime.now();

    DateTime? expiresAt = _parseDateTime(json['expiresAt']);
    if (expiresAt == null) {
      if (json['expiresInSeconds'] is num) {
        final secs = (json['expiresInSeconds'] as num).toInt();
        expiresAt = offeredAt.add(Duration(seconds: secs));
      } else if (json['timeoutSeconds'] is num) {
        final secs = (json['timeoutSeconds'] as num).toInt();
        expiresAt = offeredAt.add(Duration(seconds: secs));
      } else {
        expiresAt = offeredAt.add(const Duration(seconds: 30)); // fallback 30s
      }
    }

    // 2. Parse payout (handling rupees vs paise, estimatedEarnings, deliveryFee)
    double payout = 0.0;
    if (json['payout'] is num) {
      payout = (json['payout'] as num).toDouble();
    } else if (json['payoutPaise'] is num) {
      payout = (json['payoutPaise'] as num) / 100.0;
    } else if (json['estimatedEarnings'] is num) {
      payout = (json['estimatedEarnings'] as num).toDouble();
    } else if (json['estimatedEarningsPaise'] is num) {
      payout = (json['estimatedEarningsPaise'] as num) / 100.0;
    } else if (json['deliveryFee'] is num) {
      payout = (json['deliveryFee'] as num).toDouble();
    } else if (json['deliveryFeePaise'] is num) {
      payout = (json['deliveryFeePaise'] as num) / 100.0;
    } else if (json['earningAmount'] is num) {
      payout = (json['earningAmount'] as num).toDouble();
    }

    // 3. Pickup & drop addresses
    final restaurantName = (json['restaurantName'] ??
            json['storeName'] ??
            json['pickupName'] ??
            'Qikzoo Merchant')
        .toString();
    final restaurantAddress = (json['restaurantAddress'] ??
            json['pickupAddress'] ??
            json['pickupLocation'] ??
            '')
        .toString();
    final customerName = (json['customerName'] ??
            json['userName'] ??
            json['dropName'] ??
            'Customer')
        .toString();
    final userAddress = (json['userAddress'] ??
            json['dropAddress'] ??
            json['deliveryAddress'] ??
            '')
        .toString();

    // 4. Distances
    final distanceKm = json['distanceKm'] is num
        ? (json['distanceKm'] as num).toDouble()
        : (json['pickupDistanceKm'] is num
            ? (json['pickupDistanceKm'] as num).toDouble()
            : 0.0);

    final dropDistanceKm = json['dropDistanceKm'] is num
        ? (json['dropDistanceKm'] as num).toDouble()
        : (json['deliveryDistanceKm'] is num
            ? (json['deliveryDistanceKm'] as num).toDouble()
            : 0.0);

    // 5. Coordinates
    final pickupLat = json['pickupLat'] is num
        ? (json['pickupLat'] as num).toDouble()
        : (json['restaurantLat'] is num
            ? (json['restaurantLat'] as num).toDouble()
            : (json['storeLat'] is num
                ? (json['storeLat'] as num).toDouble()
                : null));
    final pickupLng = json['pickupLng'] is num
        ? (json['pickupLng'] as num).toDouble()
        : (json['restaurantLng'] is num
            ? (json['restaurantLng'] as num).toDouble()
            : (json['storeLng'] is num
                ? (json['storeLng'] as num).toDouble()
                : null));
    final dropLat = json['dropLat'] is num
        ? (json['dropLat'] as num).toDouble()
        : (json['userLat'] is num
            ? (json['userLat'] as num).toDouble()
            : (json['deliveryLat'] is num
                ? (json['deliveryLat'] as num).toDouble()
                : null));
    final dropLng = json['dropLng'] is num
        ? (json['dropLng'] as num).toDouble()
        : (json['userLng'] is num
            ? (json['userLng'] as num).toDouble()
            : (json['deliveryLng'] is num
                ? (json['deliveryLng'] as num).toDouble()
                : null));

    return DispatchOfferModel(
      id: json['id'] is String ? json['id'] as String : '',
      jobId: json['jobId'] is String ? json['jobId'] as String : '',
      attemptNumber: json['attemptNumber'] is num
          ? (json['attemptNumber'] as num).toInt()
          : 0,
      status: DispatchAttemptStatus.fromBackend(json['status']),
      distanceKm: distanceKm,
      searchRadiusKm: json['searchRadiusKm'] is num
          ? (json['searchRadiusKm'] as num).toDouble()
          : null,
      broadcast: json['broadcast'] == true,
      offeredAt: offeredAt,
      expiresAt: expiresAt,
      payout: payout,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      customerName: customerName,
      userAddress: userAddress,
      dropDistanceKm: dropDistanceKm,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropLat: dropLat,
      dropLng: dropLng,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'attemptNumber': attemptNumber,
        'status': switch (status) {
          DispatchAttemptStatus.waitingRider => 'WAITING_RIDER',
          DispatchAttemptStatus.accepted => 'ACCEPTED',
          DispatchAttemptStatus.rejected => 'REJECTED',
          DispatchAttemptStatus.expired => 'EXPIRED',
          DispatchAttemptStatus.cancelled => 'CANCELLED',
          DispatchAttemptStatus.unknown => 'UNKNOWN',
        },
        'distanceKm': distanceKm,
        'searchRadiusKm': searchRadiusKm,
        'broadcast': broadcast,
        'offeredAt': offeredAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'payout': payout,
        'restaurantName': restaurantName,
        'restaurantAddress': restaurantAddress,
        'customerName': customerName,
        'userAddress': userAddress,
        'dropDistanceKm': dropDistanceKm,
      };

  @override
  List<Object?> get props => [
        id,
        jobId,
        attemptNumber,
        status,
        distanceKm,
        searchRadiusKm,
        broadcast,
        offeredAt,
        expiresAt,
        payout,
        restaurantName,
        restaurantAddress,
        customerName,
        userAddress,
        dropDistanceKm,
      ];
}
