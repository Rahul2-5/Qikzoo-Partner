import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/location/rider_location_ping.dart';
import '../../repositories/location/location_repository.dart';
import '../api/api_client.dart';
import '../api/dio_service.dart';
import '../storage/secure_storage.dart';
import 'location_movement_state.dart';

/// The `flutter_foreground_task` entry point — runs in a separate isolate
/// from the main UI isolate, so it cannot reach the app's Riverpod
/// `ProviderContainer`. It doesn't need to: `DioService` and
/// `SecureTokenStorage` are plain Dart classes with no Riverpod dependency
/// (`flutter_secure_storage` and `dio` both work over platform channels
/// from any isolate), so this reconstructs the exact same
/// `DioLocationRepository` P0-1 uses — same endpoint, same DTO, same
/// token-refresh interceptor — rather than hand-rolling a second HTTP
/// client or a second location endpoint.
///
/// Must stay a top-level function annotated `@pragma('vm:entry-point')` —
/// the Android engine invokes it directly, the same requirement
/// `firebaseMessagingBackgroundHandler` in push_service.dart already
/// follows.
@pragma('vm:entry-point')
void riderLocationTaskCallback() {
  FlutterForegroundTask.setTaskHandler(RiderLocationTaskHandler());
}

class RiderLocationTaskHandler extends TaskHandler {
  LocationRepository? _repository;
  int _lastSequence = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final dioService = DioService(SecureTokenStorage());
    _repository = DioLocationRepository(
      apiClient: ApiClient(dioService.dio),
    );
  }

  /// Fires on the interval configured in
  /// `RiderBackgroundLocationService.initialize()` (mirrors
  /// `LocationPingPolicy.background`) — this handler only ever reports
  /// `movementState: background`, since by definition it's only actually
  /// doing anything while the foreground tracker in the main isolate isn't
  /// (see the coordination note on `RiderBackgroundLocationService`).
  @override
  void onRepeatEvent(DateTime timestamp) async {
    final repository = _repository;
    if (repository == null) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      await repository.sendPing(
        RiderLocationPing(
          lat: position.latitude,
          lng: position.longitude,
          accuracy: position.accuracy.isNaN ? null : position.accuracy,
          heading: position.heading.isNaN ? null : position.heading,
          speed: position.speed.isNaN ? null : position.speed,
          movementState: LocationMovementState.background,
          recordedAt: position.timestamp,
          sequence: _nextSequence(),
        ),
      );
    } catch (_) {
      // Swallowed deliberately — a single failed background ping must
      // never crash the isolate/service. If pings keep failing, the
      // backend's own stale-presence sweep (120s) force-offlines the rider
      // rather than leaving them silently stuck "available" server-side.
    }
  }

  int _nextSequence() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _lastSequence = now > _lastSequence ? now : _lastSequence + 1;
    return _lastSequence;
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}
