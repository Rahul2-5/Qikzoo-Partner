/// Mirrors the backend's `LocationMovementState` exactly
/// (`rider-location/dto/update-location.dto.ts`) — the wire values are the
/// same three strings the adaptive-ping-interval pipeline keys off of.
enum LocationMovementState {
  moving,
  idle,
  background;

  String get wireValue => switch (this) {
        LocationMovementState.moving => 'MOVING',
        LocationMovementState.idle => 'IDLE',
        LocationMovementState.background => 'BACKGROUND',
      };
}
