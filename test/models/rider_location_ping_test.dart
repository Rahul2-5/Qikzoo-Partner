import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/core/location/location_movement_state.dart';
import 'package:delivery_partner_app/models/location/rider_location_ping.dart';

void main() {
  test('serializes capture time and monotonic sequence for backend ordering',
      () {
    final ping = RiderLocationPing(
      lat: 19.111123,
      lng: 72.927891,
      accuracy: 8.4,
      heading: 126,
      speed: 7.3,
      movementState: LocationMovementState.moving,
      recordedAt: DateTime.parse('2026-08-27T10:21:34.218Z'),
      sequence: 184,
    );

    expect(ping.toJson(), {
      'lat': 19.111123,
      'lng': 72.927891,
      'accuracy': 8.4,
      'heading': 126,
      'speed': 7.3,
      'movementState': 'MOVING',
      'recordedAt': '2026-08-27T10:21:34.218Z',
      'sequence': 184,
    });
  });
}
