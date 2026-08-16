import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Thin seam around the static `Geolocator` calls
/// `RiderLocationController` uses, so it can be exercised in widget tests
/// (e.g. `dashboard_home_screen_test.dart`'s "go online" flow) without a
/// real GPS/location platform channel, which throws
/// `MissingPluginException` in a test harness with no device attached.
/// Every real call site goes through [locationPlatformProvider]; tests
/// override it with a fake instead of touching `Geolocator` directly.
abstract class LocationPlatform {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> getCurrentPosition({Duration? timeLimit});
  Stream<Position> getPositionStream({required int distanceFilterMeters});
  Future<bool> openLocationSettings();
  Future<bool> openAppSettings();
}

class GeolocatorLocationPlatform implements LocationPlatform {
  const GeolocatorLocationPlatform();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition({Duration? timeLimit}) =>
      Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );

  @override
  Stream<Position> getPositionStream({required int distanceFilterMeters}) =>
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilterMeters,
        ),
      );

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}

final locationPlatformProvider = Provider<LocationPlatform>(
  (ref) => const GeolocatorLocationPlatform(),
);
