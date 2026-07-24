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
/// (backend's bare `DispatchAttempt` row — `DispatchEngineService.
/// getCurrentOffer`). The backend does not join in the restaurant name,
/// pickup address, ETA, or estimated earnings on this endpoint — only
/// `distanceKm` and the offer's own timing are available before the rider
/// decides, so the offer screen only ever shows what's genuinely here
/// rather than inventing fields the backend doesn't provide.
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
      ];
}
