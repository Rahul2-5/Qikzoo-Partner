import 'package:equatable/equatable.dart';

/// Mirrors the backend's `RiderAvailabilityStatus` enum exactly
/// (rider-availability/logic/rider-availability.transitions.ts). The Go
/// Online toggle now drives the full OFFLINE→ONLINE→AVAILABLE chain (see
/// `DashboardHomeScreen._goOnline` — ONLINE alone doesn't make a rider
/// dispatch-eligible; only AVAILABLE does), sending a location ping before
/// the AVAILABLE transition so the backend has a position to mirror into
/// Redis GEO. BUSY/BREAK remain dispatch/order-driven states not reachable
/// from this toggle, parsed and displayed read-only so the dashboard never
/// shows a wrong/blank status for a rider mid-delivery.
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

  /// The three states the rider-facing status pill/badge (Orders tab,
  /// Dashboard shift badge) distinguish visually — every other backend
  /// status (BREAK, LOGGED_OUT, unknown) collapses to [offline] rather than
  /// inventing a fourth visual state nothing in the UI currently designs
  /// for. Derived directly from the authoritative enum value, never from a
  /// boolean like "isOnline" alone, so BUSY can't be silently swallowed
  /// into an online/offline binary the way it once was on the Orders tab.
  RiderStatusTone get statusTone => switch (this) {
        RiderAvailabilityStatus.online ||
        RiderAvailabilityStatus.available =>
          RiderStatusTone.online,
        RiderAvailabilityStatus.busy => RiderStatusTone.busy,
        _ => RiderStatusTone.offline,
      };

  /// Short chip label for [statusTone] — distinct from the fuller,
  /// backend-facing [label] above ("On a delivery"); this is the compact
  /// wording the Orders tab pill and Dashboard shift badge render.
  String get statusChipLabel => switch (statusTone) {
        RiderStatusTone.online => 'Online',
        RiderStatusTone.busy => 'Busy',
        RiderStatusTone.offline => 'Offline',
      };
}

/// See [RiderAvailabilityStatus.statusTone].
enum RiderStatusTone { online, busy, offline }

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

  /// The rider's total online duration today, in seconds — computed
  /// server-side from availability history (`GET /rider/earnings/summary`'s
  /// `today.onlineSecondsToday`), never estimated client-side.
  final int onlineSecondsToday;

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
    required this.onlineSecondsToday,
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
        onlineSecondsToday: onlineSecondsToday,
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
        onlineSecondsToday,
        acceptanceRatePercent,
        completionRatePercent,
        rating,
        workingZone,
      ];
}
