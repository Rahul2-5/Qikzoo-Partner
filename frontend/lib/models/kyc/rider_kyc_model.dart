import 'package:equatable/equatable.dart';

/// Mirrors the free-text `governmentIdType` field on the backend's
/// `RiderKyc` model (`governmentIdType?: string`) — the backend accepts
/// any string, but the app only ever offers these four real Indian
/// government IDs, so the raw string is parsed into this closed set at the
/// repository boundary (same pattern as [Gender] on `PartnerProfileModel`).
enum GovernmentIdType { aadhaar, pan, voterId, passport }

extension GovernmentIdTypeX on GovernmentIdType {
  String get label => switch (this) {
        GovernmentIdType.aadhaar => 'Aadhaar Card',
        GovernmentIdType.pan => 'PAN Card',
        GovernmentIdType.voterId => 'Voter ID',
        GovernmentIdType.passport => 'Passport',
      };

  String get backendValue => switch (this) {
        GovernmentIdType.aadhaar => 'AADHAAR',
        GovernmentIdType.pan => 'PAN',
        GovernmentIdType.voterId => 'VOTER_ID',
        GovernmentIdType.passport => 'PASSPORT',
      };
}

/// Mirrors the backend's `RiderDocumentStatus` enum
/// (`prisma/schema.prisma`) — the review state of the rider's KYC
/// submission as a whole.
enum KycDocumentStatus { pending, approved, rejected, unknown }

/// A rider's KYC submission — government ID, driving licence and bank
/// payout details — as returned by `GET /rider/kyc` / `PUT /rider/kyc`
/// (backend's `RiderKycView`, `rider-kyc.service.ts`). The backend folds
/// identity and bank details into this single section (no separate "Bank"
/// endpoint or onboarding lock exists), so this one model/repository
/// covers all of it.
class RiderKycModel extends Equatable {
  final GovernmentIdType? governmentIdType;
  final String? governmentIdNumber;

  /// Raw private-bucket storage key, NOT a browsable URL — unlike
  /// `profilePhotoUrl`/`selfieUrl`, the backend's `RiderKycService.toView()`
  /// does not resolve this to a signed URL on read. Only usable here as a
  /// "has the rider uploaded this document" presence flag.
  final String? governmentIdDocumentUrl;

  final String? drivingLicenseNumber;
  final DateTime? drivingLicenseExpiry;

  /// Same private-key caveat as [governmentIdDocumentUrl].
  final String? drivingLicenseDocumentUrl;

  final String? bankAccountHolderName;

  /// e.g. "•••• 9012" — the backend never returns the plaintext account
  /// number once saved, only this masked form.
  final String? bankAccountNumberMasked;
  final String? bankIfsc;
  final String? bankName;

  final KycDocumentStatus status;
  final String? rejectionReason;

  const RiderKycModel({
    this.governmentIdType,
    this.governmentIdNumber,
    this.governmentIdDocumentUrl,
    this.drivingLicenseNumber,
    this.drivingLicenseExpiry,
    this.drivingLicenseDocumentUrl,
    this.bankAccountHolderName,
    this.bankAccountNumberMasked,
    this.bankIfsc,
    this.bankName,
    this.status = KycDocumentStatus.pending,
    this.rejectionReason,
  });

  bool get hasGovernmentIdDocument =>
      (governmentIdDocumentUrl ?? '').isNotEmpty;

  bool get hasDrivingLicenseDocument =>
      (drivingLicenseDocumentUrl ?? '').isNotEmpty;

  bool get hasBankAccountOnFile => (bankAccountNumberMasked ?? '').isNotEmpty;

  factory RiderKycModel.fromJson(Map<String, dynamic> json) {
    return RiderKycModel(
      governmentIdType: _typeFrom(json['governmentIdType']),
      governmentIdNumber: _str(json['governmentIdNumber']),
      governmentIdDocumentUrl: _str(json['governmentIdDocumentUrl']),
      drivingLicenseNumber: _str(json['drivingLicenseNumber']),
      drivingLicenseExpiry: _date(json['drivingLicenseExpiry']),
      drivingLicenseDocumentUrl: _str(json['drivingLicenseDocumentUrl']),
      bankAccountHolderName: _str(json['bankAccountHolderName']),
      bankAccountNumberMasked: _str(json['bankAccountNumberMasked']),
      bankIfsc: _str(json['bankIfsc']),
      bankName: _str(json['bankName']),
      status: _statusFrom(json['status']),
      rejectionReason: _str(json['rejectionReason']),
    );
  }

  static String? _str(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static GovernmentIdType? _typeFrom(Object? value) => switch (value) {
        'AADHAAR' => GovernmentIdType.aadhaar,
        'PAN' => GovernmentIdType.pan,
        'VOTER_ID' => GovernmentIdType.voterId,
        'PASSPORT' => GovernmentIdType.passport,
        _ => null,
      };

  static KycDocumentStatus _statusFrom(Object? value) => switch (value) {
        'PENDING' => KycDocumentStatus.pending,
        'APPROVED' => KycDocumentStatus.approved,
        'REJECTED' => KycDocumentStatus.rejected,
        _ => KycDocumentStatus.unknown,
      };

  @override
  List<Object?> get props => [
        governmentIdType,
        governmentIdNumber,
        governmentIdDocumentUrl,
        drivingLicenseNumber,
        drivingLicenseExpiry,
        drivingLicenseDocumentUrl,
        bankAccountHolderName,
        bankAccountNumberMasked,
        bankIfsc,
        bankName,
        status,
        rejectionReason,
      ];
}
