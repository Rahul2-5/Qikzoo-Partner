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
  });

  Duration get remaining {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isExpired => remaining == Duration.zero;

  factory DispatchOfferModel.fromJson(Map<String, dynamic> json) {
    return DispatchOfferModel(
      id: json['id'] is String ? json['id'] as String : '',
      jobId: json['jobId'] is String ? json['jobId'] as String : '',
      attemptNumber: json['attemptNumber'] is num
          ? (json['attemptNumber'] as num).toInt()
          : 0,
      status: DispatchAttemptStatus.fromBackend(json['status']),
      distanceKm: json['distanceKm'] is num
          ? (json['distanceKm'] as num).toDouble()
          : 0,
      searchRadiusKm: json['searchRadiusKm'] is num
          ? (json['searchRadiusKm'] as num).toDouble()
          : null,
      broadcast: json['broadcast'] == true,
      offeredAt: DateTime.tryParse('${json['offeredAt']}') ?? DateTime.now(),
      expiresAt: DateTime.tryParse('${json['expiresAt']}') ?? DateTime.now(),
      payout: json['payout'] is num ? (json['payout'] as num).toDouble() : 0,
      restaurantName: json['restaurantName'] is String
          ? json['restaurantName'] as String
          : 'Qikzoo Merchant',
      restaurantAddress: json['restaurantAddress'] is String
          ? json['restaurantAddress'] as String
          : '',
      customerName: json['customerName'] is String
          ? json['customerName'] as String
          : 'Customer',
      userAddress:
          json['userAddress'] is String ? json['userAddress'] as String : '',
      dropDistanceKm: json['dropDistanceKm'] is num
          ? (json['dropDistanceKm'] as num).toDouble()
          : 0,
    );
  }

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
