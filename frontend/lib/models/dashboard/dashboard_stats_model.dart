import 'package:equatable/equatable.dart';

/// Mirrors the backend's `RiderAvailabilityStatus` enum exactly
/// (rider-availability/logic/rider-availability.transitions.ts) — this
/// phase's Go Online/Offline toggle only drives ONLINE/OFFLINE directly;
/// AVAILABLE/BUSY/BREAK are dispatch/order-driven states not yet reachable
/// from this client, but are still parsed and displayed read-only so the
/// dashboard never shows a wrong/blank status for a rider mid-delivery.
enum RiderAvailabilityStatus {
  offline,
  online,
  available,
  busy,
  onBreak,
  loggedOut,
  unknown;

  static RiderAvailabilityStatus fromBackend(String? value) {
    return switch (value) {
      'OFFLINE' => RiderAvailabilityStatus.offline,
      'ONLINE' => RiderAvailabilityStatus.online,
      'AVAILABLE' => RiderAvailabilityStatus.available,
      'BUSY' => RiderAvailabilityStatus.busy,
      'BREAK' => RiderAvailabilityStatus.onBreak,
      'LOGGED_OUT' => RiderAvailabilityStatus.loggedOut,
      _ => RiderAvailabilityStatus.unknown,
    };
  }

  /// Whether this status should render the toggle as "online" (the two
  /// states this phase's toggle actually drives) — every other state is
  /// still shown via [label], just without an active toggle affordance.
  bool get isOnlineFacing =>
      this == RiderAvailabilityStatus.online ||
      this == RiderAvailabilityStatus.available ||
      this == RiderAvailabilityStatus.busy;

  String get label => switch (this) {
        RiderAvailabilityStatus.offline => 'Offline',
        RiderAvailabilityStatus.online => 'Online',
        RiderAvailabilityStatus.available => 'Available',
        RiderAvailabilityStatus.busy => 'On a delivery',
        RiderAvailabilityStatus.onBreak => 'On break',
        RiderAvailabilityStatus.loggedOut => 'Logged out',
        RiderAvailabilityStatus.unknown => 'Unknown',
      };
}

/// Rider dashboard home summary — combines `GET /rider/profile`
/// (name/availability/rating/acceptance-completion counters/city+state),
/// `GET /rider/earnings/summary` (today's earnings+deliveries) and
/// `GET /rider/wallet` (available balance). All amounts are paise (matching
/// backend storage) — convert with `/ 100.0` only at display time.
class DashboardStatsModel extends Equatable {
  final String riderName;
  final RiderAvailabilityStatus availabilityStatus;
  final int todaysEarningsPaise;
  final int todaysDeliveries;
  final int walletBalancePaise;

  /// Null when the rider has never received a dispatch offer yet
  /// (`totalOffers == 0` — backend has no rate to report, not a 0% rate).
  final double? acceptanceRatePercent;

  /// Null when the rider has never accepted an offer yet
  /// (`totalAccepted == 0`). Derived as
  /// `(totalAccepted - totalOrdersCancelled) / totalAccepted * 100` — of
  /// the deliveries this rider took on, the share actually completed
  /// rather than cancelled after acceptance.
  final double? completionRatePercent;

  final double rating;

  /// The rider's registered service city (+ state) — the backend has no
  /// separate geofenced "zone" concept for riders, so this is the closest
  /// real, existing field or an app-invented location.
  final String? workingZone;

  const DashboardStatsModel({
    required this.riderName,
    required this.availabilityStatus,
    required this.todaysEarningsPaise,
    required this.todaysDeliveries,
    required this.walletBalancePaise,
    required this.acceptanceRatePercent,
    required this.completionRatePercent,
    required this.rating,
    required this.workingZone,
  });

  DashboardStatsModel copyWith({RiderAvailabilityStatus? availabilityStatus}) =>
      DashboardStatsModel(
        riderName: riderName,
        availabilityStatus: availabilityStatus ?? this.availabilityStatus,
        todaysEarningsPaise: todaysEarningsPaise,
        todaysDeliveries: todaysDeliveries,
        walletBalancePaise: walletBalancePaise,
        acceptanceRatePercent: acceptanceRatePercent,
        completionRatePercent: completionRatePercent,
        rating: rating,
        workingZone: workingZone,
      );

  @override
  List<Object?> get props => [
        riderName,
        availabilityStatus,
        todaysEarningsPaise,
        todaysDeliveries,
        walletBalancePaise,
        acceptanceRatePercent,
        completionRatePercent,
        rating,
        workingZone,
      ];
}
