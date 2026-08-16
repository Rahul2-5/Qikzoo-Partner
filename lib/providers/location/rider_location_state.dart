import 'package:equatable/equatable.dart';

/// Result of a permission/services readiness check, returned by
/// `RiderLocationController.ensureReadyForOnline()` so the dashboard's
/// "Go Online" flow can react to each case with a distinct, honest message
/// instead of a single generic failure.
enum LocationReadiness {
  ready,
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
}

/// Drives the dashboard's location-status UI. Deliberately a separate
/// state machine from the backend's `RiderAvailabilityStatus` — this one
/// only ever describes the health of the on-device GPS/ping loop, never
/// claims a backend transition that hasn't actually succeeded.
enum RiderLocationTrackingStatus {
  /// Not tracking — rider is offline, or tracking hasn't started yet.
  idle,

  /// Checking permission/services as part of a Go Online attempt.
  checkingPermission,

  /// Device location services are turned off entirely.
  servicesDisabled,

  /// Permission denied (recoverable — can ask again).
  permissionDenied,

  /// Permission permanently denied — only fixable from OS Settings.
  permissionDeniedForever,

  /// Permission/services are fine; waiting on the first GPS fix.
  acquiring,

  /// Tracking loop running and the most recent ping succeeded recently.
  active,

  /// Tracking loop running, but pings have been failing or a fix hasn't
  /// landed within `LocationPingPolicy.staleAfter` — dispatch eligibility
  /// may be at risk even though the rider still believes they're online.
  signalLost,
}

class RiderLocationTrackingState extends Equatable {
  final RiderLocationTrackingStatus status;
  final double? lastLat;
  final double? lastLng;
  final DateTime? lastPingAt;
  final DateTime? lastPingAttemptAt;
  final String? lastError;

  const RiderLocationTrackingState({
    required this.status,
    this.lastLat,
    this.lastLng,
    this.lastPingAt,
    this.lastPingAttemptAt,
    this.lastError,
  });

  static const idle = RiderLocationTrackingState(
    status: RiderLocationTrackingStatus.idle,
  );

  bool get isTracking =>
      status == RiderLocationTrackingStatus.active ||
      status == RiderLocationTrackingStatus.acquiring ||
      status == RiderLocationTrackingStatus.signalLost;

  RiderLocationTrackingState copyWith({
    RiderLocationTrackingStatus? status,
    double? lastLat,
    double? lastLng,
    DateTime? lastPingAt,
    DateTime? lastPingAttemptAt,
    String? lastError,
    bool clearError = false,
  }) =>
      RiderLocationTrackingState(
        status: status ?? this.status,
        lastLat: lastLat ?? this.lastLat,
        lastLng: lastLng ?? this.lastLng,
        lastPingAt: lastPingAt ?? this.lastPingAt,
        lastPingAttemptAt: lastPingAttemptAt ?? this.lastPingAttemptAt,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );

  @override
  List<Object?> get props => [
        status,
        lastLat,
        lastLng,
        lastPingAt,
        lastPingAttemptAt,
        lastError,
      ];
}
