import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'location_ping_policy.dart';
import 'rider_location_task_handler.dart';

/// Owns the Android foreground-service side of P0-2 — a persistent,
/// user-visible notification that keeps the app process alive so location
/// pings can keep flowing while the app is backgrounded. Android-only,
/// mirroring `PushService`'s own Android-only scoping (no iOS
/// configuration exists for either yet).
///
/// Deliberately **not** required to go online at all — foreground tracking
/// (`RiderLocationController`, P0-1) works on its own the moment a rider
/// taps Go Online. This service is an additive enhancement the rider opts
/// into separately, consistent with not "blindly" requesting background
/// location alongside the core permission flow (a Play Store review
/// expectation, not just a nicety).
///
/// Coordination with the foreground tracker: both can legitimately be
/// running the same moment the app happens to be in the foreground (this
/// service keeps running continuously for the whole online session, not
/// only while backgrounded, since a plain Dart `Timer`/isolate has no
/// reliable way to detect the exact instant the OS would otherwise
/// suspend it). Their ping cadences don't overlap in practice — the
/// foreground tracker pings every 5-20s per `LocationPingPolicy`, this
/// service's own repeat interval is fixed at the coarse `background`
/// bucket (60s) — and a slightly redundant extra ping every minute is
/// harmless: `POST /rider/location` is idempotent per call and the
/// backend's own dedup logic already collapses near-duplicate history
/// rows. Documented here rather than solved with cross-isolate
/// foreground/background signalling, which would add real complexity for
/// a self-correcting, harmless overlap.
class RiderBackgroundLocationService {
  RiderBackgroundLocationService._();
  static final RiderBackgroundLocationService instance =
      RiderBackgroundLocationService._();

  static const _serviceId = 100;
  static const _channelId = 'rider_location_tracking';

  bool _initialized = false;

  /// Call once at app start (see main.dart) — cheap, just registers the
  /// notification channel/options; does not request any permission or
  /// start the service.
  void initialize() {
    if (!Platform.isAndroid || _initialized) return;
    _initialized = true;

    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: 'Location sharing',
        channelDescription:
            'Shown while you are online and sharing your live location so nearby delivery offers can reach you.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          LocationPingPolicy.background.inMilliseconds,
        ),
        // A rider must explicitly go online again after a reboot or app
        // update — this service never silently resumes without them.
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// True only if the OS has already granted "Allow all the time" location
  /// access — never triggers a request. Used to decide whether to silently
  /// start the service on go-online, versus showing the dashboard's
  /// opt-in "Enable background location" affordance instead.
  Future<bool> hasBackgroundPermission() async {
    if (!Platform.isAndroid) return false;
    return (await ph.Permission.locationAlways.status).isGranted;
  }

  /// The explicit opt-in request, only ever triggered by the rider
  /// tapping "Enable" on the dashboard — never called automatically.
  /// Requires foreground location to already be granted (Android enforces
  /// this at the OS level; P0-1's go-online flow guarantees it before a
  /// rider can even be online to see this affordance).
  Future<bool> requestBackgroundPermission() async {
    if (!Platform.isAndroid) return false;
    final status = await ph.Permission.locationAlways.request();
    return status.isGranted;
  }

  Future<bool> isRunning() async {
    if (!Platform.isAndroid) return false;
    return FlutterForegroundTask.isRunningService;
  }

  /// Starts (or restarts, if already running — never a duplicate) the
  /// foreground service. No-ops quietly if background permission isn't
  /// granted; the dashboard is responsible for only offering this once
  /// [hasBackgroundPermission] is true.
  Future<void> start() async {
    if (!Platform.isAndroid) return;
    if (!await hasBackgroundPermission()) return;
    initialize();

    if (await isRunning()) {
      await FlutterForegroundTask.restartService();
      return;
    }
    await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: "You're online",
      notificationText:
          'Sharing your live location so nearby delivery offers can reach you.',
      callback: riderLocationTaskCallback,
    );
  }

  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    if (await isRunning()) {
      await FlutterForegroundTask.stopService();
    }
  }
}
