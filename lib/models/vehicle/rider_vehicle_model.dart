import 'package:equatable/equatable.dart';

/// Mirrors the backend's `RiderVehicleType` enum (`prisma/schema.prisma`).
enum VehicleType { bike, scooter, bicycle, car }

extension VehicleTypeX on VehicleType {
  String get label => switch (this) {
        VehicleType.bike => 'Bike',
        VehicleType.scooter => 'Scooter',
        VehicleType.bicycle => 'Bicycle',
        VehicleType.car => 'Car',
      };

  String get backendValue => switch (this) {
        VehicleType.bike => 'BIKE',
        VehicleType.scooter => 'SCOOTER',
        VehicleType.bicycle => 'BICYCLE',
        VehicleType.car => 'CAR',
      };

  static VehicleType? fromBackend(Object? value) => switch (value) {
        'BIKE' => VehicleType.bike,
        'SCOOTER' => VehicleType.scooter,
        'BICYCLE' => VehicleType.bicycle,
        'CAR' => VehicleType.car,
        _ => null,
      };
}

/// Mirrors the backend's `RiderDocumentStatus` enum — same shared
/// three-state document/submission lifecycle as [KycDocumentStatus].
enum VehicleDocumentStatus { pending, approved, rejected, unknown }

VehicleDocumentStatus vehicleDocumentStatusFrom(Object? value) =>
    switch (value) {
      'PENDING' => VehicleDocumentStatus.pending,
      'APPROVED' => VehicleDocumentStatus.approved,
      'REJECTED' => VehicleDocumentStatus.rejected,
      _ => VehicleDocumentStatus.unknown,
    };

/// A rider's registered vehicle, as returned by `GET/POST /rider/vehicles`
/// (backend's `RiderVehicle` row). A rider may have several over time —
/// at most one `isActive` — but the backend has no endpoint to edit an
/// existing vehicle's text fields (type/registrationNumber/insurance
/// number/rc number) once created; only its two documents can be
/// (re)uploaded, and a brand new vehicle can be registered separately.
class RiderVehicleModel extends Equatable {
  final String id;
  final VehicleType type;
  final String registrationNumber;
  final String? insuranceNumber;
  final DateTime? insuranceExpiry;
  final String? insuranceDocumentUrl;
  final String? rcNumber;
  final String? rcDocumentUrl;
  final bool isActive;
  final VehicleDocumentStatus status;
  final String? rejectionReason;

  const RiderVehicleModel({
    required this.id,
    required this.type,
    required this.registrationNumber,
    this.insuranceNumber,
    this.insuranceExpiry,
    this.insuranceDocumentUrl,
    this.rcNumber,
    this.rcDocumentUrl,
    required this.isActive,
    this.status = VehicleDocumentStatus.pending,
    this.rejectionReason,
  });

  bool get hasRcDocument => (rcDocumentUrl ?? '').isNotEmpty;
  bool get hasInsuranceDocument => (insuranceDocumentUrl ?? '').isNotEmpty;

  bool get isInsuranceExpired =>
      insuranceExpiry != null && insuranceExpiry!.isBefore(DateTime.now());

  /// Mirrors the backend's own `isVehicleSectionComplete` per-vehicle
  /// check exactly (`rider-onboarding-completion.ts`).
  bool get isComplete =>
      status != VehicleDocumentStatus.rejected &&
      registrationNumber.trim().isNotEmpty &&
      hasRcDocument &&
      hasInsuranceDocument &&
      !isInsuranceExpired;

  factory RiderVehicleModel.fromJson(Map<String, dynamic> json) {
    return RiderVehicleModel(
      id: json['id'] is String ? json['id'] as String : '',
      type: VehicleTypeX.fromBackend(json['type']) ?? VehicleType.bike,
      registrationNumber: json['registrationNumber'] is String
          ? json['registrationNumber'] as String
          : '',
      insuranceNumber: _str(json['insuranceNumber']),
      insuranceExpiry: _date(json['insuranceExpiry']),
      insuranceDocumentUrl: _str(json['insuranceDocumentUrl']),
      rcNumber: _str(json['rcNumber']),
      rcDocumentUrl: _str(json['rcDocumentUrl']),
      isActive: json['isActive'] == true,
      status: vehicleDocumentStatusFrom(json['status']),
      rejectionReason: _str(json['rejectionReason']),
    );
  }

  static String? _str(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  @override
  List<Object?> get props => [
        id,
        type,
        registrationNumber,
        insuranceNumber,
        insuranceExpiry,
        insuranceDocumentUrl,
        rcNumber,
        rcDocumentUrl,
        isActive,
        status,
        rejectionReason,
      ];
}
