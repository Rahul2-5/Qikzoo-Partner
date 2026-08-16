import '../../core/location/location_movement_state.dart';

/// Request payload for `POST /rider/location`
/// (`UpdateRiderLocationDto`) — field-for-field match, including which
/// fields are optional there.
class RiderLocationPing {
  final double lat;
  final double lng;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final int? batteryPercent;
  final LocationMovementState movementState;

  const RiderLocationPing({
    required this.lat,
    required this.lng,
    required this.movementState,
    this.accuracy,
    this.heading,
    this.speed,
    this.batteryPercent,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (accuracy != null) 'accuracy': accuracy,
        if (heading != null && !heading!.isNaN) 'heading': heading,
        if (speed != null) 'speed': speed,
        if (batteryPercent != null) 'batteryPercent': batteryPercent,
        'movementState': movementState.wireValue,
      };
}
