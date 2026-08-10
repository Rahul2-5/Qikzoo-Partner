import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// One combined `governmentId` slot, not separate Aadhaar/PAN slots — the
/// backend's `RiderKyc` stores a single `governmentIdType` (whichever one
/// the rider chose in KYC) + one document, not one of each. No backend
/// field exists for a standalone "vehicle photo" document, so that type
/// was dropped rather than fabricated.
enum DocumentType {
  profilePhoto,
  governmentId,
  drivingLicense,
  vehicleRc,
  vehicleInsurance,
  bankProof,
}

enum DocumentStatus {
  notUploaded,
  uploading,
  pendingVerification,
  verified,
  rejected
}

class DocumentModel extends Equatable {
  final DocumentType type;
  final DocumentStatus status;
  final String? fileUrl;
  final String? rejectionReason;

  const DocumentModel({
    required this.type,
    required this.status,
    this.fileUrl,
    this.rejectionReason,
  });

  DocumentModel copyWith(
          {DocumentStatus? status, String? fileUrl, String? rejectionReason}) =>
      DocumentModel(
        type: type,
        status: status ?? this.status,
        fileUrl: fileUrl ?? this.fileUrl,
        rejectionReason: rejectionReason ?? this.rejectionReason,
      );

  @override
  List<Object?> get props => [type, status, fileUrl, rejectionReason];
}

extension DocumentTypeDisplay on DocumentType {
  String get label {
    switch (this) {
      case DocumentType.profilePhoto:
        return 'Profile Photo';
      case DocumentType.governmentId:
        return 'Government ID';
      case DocumentType.drivingLicense:
        return 'Driving License';
      case DocumentType.vehicleRc:
        return 'Vehicle RC';
      case DocumentType.vehicleInsurance:
        return 'Insurance';
      case DocumentType.bankProof:
        return 'Bank Details';
    }
  }

  bool get isOptional =>
      this == DocumentType.vehicleInsurance || this == DocumentType.bankProof;

  IconData get icon {
    switch (this) {
      case DocumentType.profilePhoto:
        return LucideIcons.userCircle;
      case DocumentType.governmentId:
        return LucideIcons.fingerprint;
      case DocumentType.drivingLicense:
        return LucideIcons.creditCard;
      case DocumentType.vehicleRc:
        return LucideIcons.car;
      case DocumentType.vehicleInsurance:
        return LucideIcons.shieldCheck;
      case DocumentType.bankProof:
        return LucideIcons.landmark;
    }
  }
}
