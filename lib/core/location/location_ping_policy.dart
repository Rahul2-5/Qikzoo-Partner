import 'location_movement_state.dart';

/// Single source of truth for how often the rider app sends a location
/// ping while online — every call site reads through here rather than
/// hardcoding a `Duration` inline.
///
/// The backend computes its own advisory cadence server-side
/// (`rider-location/logic/adaptive-ping-interval.util.ts`:
/// MOVING-fast=3s, MOVING-slow=8s, IDLE=15s, BACKGROUND=60s) but — as that
/// file's own doc comment states — it is "purely advisory: the server
/// accepts pings at any cadence regardless" and is never returned in the
/// `POST /rider/location` response body (that endpoint replies 204 with no
/// body). There is nothing to consume from the API, so this policy mirrors
/// the same four buckets and thresholds client-side instead of inventing
/// different numbers, keeping client and server cadence intentions aligned
/// without requiring a backend change.
class LocationPingPolicy {
  const LocationPingPolicy._();

  static const Duration movingFast = Duration(seconds: 5);
  static const Duration movingSlow = Duration(seconds: 10);
  static const Duration idle = Duration(seconds: 20);
  static const Duration background = Duration(seconds: 60);

  /// Speed (m/s) at or above which a MOVING rider is considered "fast" and
  /// gets the tighter ping interval — matches the backend's own threshold
  /// name (`fastSpeedMps`) even though the value isn't shared over the
  /// wire.
  static const double fastSpeedMps = 4.0;

  /// Below this speed a rider who isn't backgrounded is treated as
  /// stationary (IDLE) rather than MOVING-slow, purely a simple heuristic
  /// for the first implementation — not a tuned/validated threshold.
  static const double idleSpeedMps = 0.5;

  /// Minimum distance (metres) the position stream must move before
  /// delivering a new sample — keeps the GPS chip from waking the app for
  /// noise-level jitter while stationary.
  static const int streamDistanceFilterMeters = 10;

  /// How long a ping is allowed to be "due" before the tracker treats the
  /// signal as lost (surfaced to the dashboard as "Location signal lost").
  static const Duration staleAfter = Duration(seconds: 90);

  static Duration intervalFor(LocationMovementState state, double? speedMps) {
    switch (state) {
      case LocationMovementState.background:
        return background;
      case LocationMovementState.idle:
        return idle;
      case LocationMovementState.moving:
        return (speedMps ?? 0) >= fastSpeedMps ? movingFast : movingSlow;
    }
  }

  static LocationMovementState classify({
    required bool appInBackground,
    required double speedMps,
  }) {
    if (appInBackground) return LocationMovementState.background;
    if (speedMps < idleSpeedMps) return LocationMovementState.idle;
    return LocationMovementState.moving;
  }
}
