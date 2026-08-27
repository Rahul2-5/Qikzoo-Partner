import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api/api_exception.dart';
import '../../core/location/location_movement_state.dart';
import '../../core/location/location_ping_policy.dart';
import '../../core/location/location_platform.dart';
import '../../models/location/rider_location_ping.dart';
import '../../repositories/location/location_repository.dart';
import 'rider_location_state.dart';

/// Owns the on-device side of P0-1: permission/services checks, the GPS
/// position stream, and the adaptive ping loop that keeps
/// `POST /rider/location` fed while the rider is online. This is the piece
/// that was completely missing before — the backend's Redis GEO
/// membership, dispatch candidate search, and stale-presence sweep all
/// already existed and are untouched here.
///
/// Deliberately does not decide *when* to start/stop on its own — the
/// dashboard (the only place "Go Online"/"Go Offline" is triggered from)
/// owns that sequencing so the backend availability transition and the
/// on-device tracking loop can be kept in lockstep and rolled back
/// together on failure.
///
/// All GPS access goes through [locationPlatformProvider] rather than
/// calling `Geolocator` directly — see that file's doc comment for why
/// (testability without a real location platform channel).
class RiderLocationController extends Notifier<RiderLocationTrackingState> {
  StreamSubscription<Position>? _positionSub;
  Timer? _pingTimer;
  Position? _lastPosition;
  bool _appInBackground = false;
  int _consecutiveFailures = 0;
  int _lastSequence = 0;

  static const _maxConsecutiveFailuresBeforeSignalLost = 3;

  @override
  RiderLocationTrackingState build() {
    ref.onDispose(() {
      _positionSub?.cancel();
      _pingTimer?.cancel();
    });
    return RiderLocationTrackingState.idle;
  }

  /// Step 1 of "Go Online": services + permission only, no GPS fix yet.
  /// Safe to call repeatedly (e.g. retried after the rider opens Settings
  /// and comes back).
  Future<LocationReadiness> ensureReadyForOnline() async {
    state = state.copyWith(status: RiderLocationTrackingStatus.checkingPermission);
    final platform = ref.read(locationPlatformProvider);

    if (!await platform.isLocationServiceEnabled()) {
      state = state.copyWith(status: RiderLocationTrackingStatus.servicesDisabled);
      return LocationReadiness.servicesDisabled;
    }

    var permission = await platform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await platform.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        status: RiderLocationTrackingStatus.permissionDeniedForever,
      );
      return LocationReadiness.permissionDeniedForever;
    }
    if (permission == LocationPermission.denied) {
      state = state.copyWith(status: RiderLocationTrackingStatus.permissionDenied);
      return LocationReadiness.permissionDenied;
    }

    return LocationReadiness.ready;
  }

  /// Step 2: get one real fix before anything is reported to the backend
  /// as "online" — never fabricate a position. Returns null (and sets an
  /// error state) rather than throwing, since the caller needs to decide
  /// whether to keep the rider offline without a hard crash.
  Future<Position?> acquireInitialFix() async {
    state = state.copyWith(status: RiderLocationTrackingStatus.acquiring);
    try {
      final position = await ref
          .read(locationPlatformProvider)
          .getCurrentPosition(timeLimit: const Duration(seconds: 20));
      _lastPosition = position;
      state = state.copyWith(
        lastLat: position.latitude,
        lastLng: position.longitude,
      );
      return position;
    } catch (e) {
      state = state.copyWith(
        status: RiderLocationTrackingStatus.signalLost,
        lastError: "Couldn't get a GPS fix. Please try again.",
      );
      return null;
    }
  }

  /// Sends one ping immediately using an already-acquired position —
  /// used right after `acquireInitialFix()` so the backend has
  /// `Rider.lastLat/lastLng` set *before* the dashboard flips the rider to
  /// AVAILABLE (the transition that actually adds them to `riders:geo`
  /// only mirrors into Redis when a last-known position already exists —
  /// see `RiderAvailabilityService.transition()`).
  Future<void> sendImmediateFix(Position position) async {
    _lastPosition = position;
    await _sendPing(position, LocationMovementState.moving);
  }

  /// Step 3: start the continuous stream + adaptive ping loop. Call only
  /// after the backend availability transition has actually succeeded.
  void start() {
    if (_positionSub != null) return; // already running — no duplicate loop
    _consecutiveFailures = 0;

    _positionSub = ref
        .read(locationPlatformProvider)
        .getPositionStream(
          distanceFilterMeters: LocationPingPolicy.streamDistanceFilterMeters,
        )
        .listen(
          (position) => _lastPosition = position,
          onError: (_) {
            // Stream errors (GPS momentarily unavailable, provider disabled
            // mid-shift, etc.) don't stop the loop — the next scheduled ping
            // attempt will surface a signal-lost state via its own failure
            // path instead of tearing down tracking for a transient blip.
          },
        );

    state = state.copyWith(status: RiderLocationTrackingStatus.active, clearError: true);
    _scheduleNextPing(Duration.zero);
  }

  /// Step "Go Offline"/logout: stop the stream and the ping loop. Does
  /// NOT call the backend offline endpoint — the dashboard does that, in
  /// the order it decides (tracking is always stopped first so no ping
  /// can race a completed offline transition).
  void stop() {
    _positionSub?.cancel();
    _positionSub = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _lastPosition = null;
    _consecutiveFailures = 0;
    state = RiderLocationTrackingState.idle;
  }

  /// Called from the dashboard's `didChangeAppLifecycleState` so the
  /// movement-state classification (and therefore ping cadence) reflects
  /// foreground vs backgrounded — independent of whether a P0-2 foreground
  /// service is also keeping the loop alive while backgrounded.
  void setAppBackgrounded(bool value) {
    _appInBackground = value;
  }

  void _scheduleNextPing(Duration delay) {
    _pingTimer?.cancel();
    _pingTimer = Timer(delay, _tick);
  }

  Future<void> _tick() async {
    var position = _lastPosition;
    if (position == null) {
      try {
        position = await ref
            .read(locationPlatformProvider)
            .getCurrentPosition(timeLimit: const Duration(seconds: 10));
        _lastPosition = position;
      } catch (_) {
        // No fix available yet — keep the loop alive with a short retry
        // rather than giving up, but be honest in the UI about it.
        state = state.copyWith(status: RiderLocationTrackingStatus.signalLost);
        _scheduleNextPing(const Duration(seconds: 10));
        return;
      }
    }

    final movementState = LocationPingPolicy.classify(
      appInBackground: _appInBackground,
      speedMps: position.speed.isNaN ? 0 : position.speed,
    );

    await _sendPing(position, movementState);

    _scheduleNextPing(LocationPingPolicy.intervalFor(movementState, position.speed));
  }

  Future<void> _sendPing(Position position, LocationMovementState movementState) async {
    state = state.copyWith(lastPingAttemptAt: DateTime.now());
    try {
      await ref.read(locationRepositoryProvider).sendPing(
            RiderLocationPing(
              lat: position.latitude,
              lng: position.longitude,
              accuracy: position.accuracy.isNaN ? null : position.accuracy,
              heading: position.heading.isNaN ? null : position.heading,
              speed: position.speed.isNaN ? null : position.speed,
              movementState: movementState,
              recordedAt: position.timestamp,
              sequence: _nextSequence(),
            ),
          );
      _consecutiveFailures = 0;
      state = state.copyWith(
        status: RiderLocationTrackingStatus.active,
        lastLat: position.latitude,
        lastLng: position.longitude,
        lastPingAt: DateTime.now(),
        clearError: true,
      );
    } catch (e) {
      _consecutiveFailures++;
      final message = e is ApiException
          ? e.message
          : 'Could not reach the server to update your location.';
      final stillLooksActive =
          _consecutiveFailures < _maxConsecutiveFailuresBeforeSignalLost;
      state = state.copyWith(
        status: stillLooksActive
            ? RiderLocationTrackingStatus.active
            : RiderLocationTrackingStatus.signalLost,
        lastError: message,
      );
      // Deliberately swallowed beyond updating state — a ping failure
      // must never crash the loop or force the rider offline; the next
      // scheduled tick tries again on its own.
    }
  }

  int _nextSequence() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _lastSequence = now > _lastSequence ? now : _lastSequence + 1;
    return _lastSequence;
  }
}

final riderLocationControllerProvider =
    NotifierProvider<RiderLocationController, RiderLocationTrackingState>(
  RiderLocationController.new,
);
