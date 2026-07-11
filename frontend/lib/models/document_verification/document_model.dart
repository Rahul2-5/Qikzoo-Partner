import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum DocumentType {
  profilePhoto,
  aadhaar,
  pan,
  drivingLicense,
  vehicleRc,
  vehicleInsurance,
  vehiclePhoto,
  bankProof,
}

enum DocumentStatus { notUploaded, uploading, pendingVerification, verified, rejected }

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

  DocumentModel copyWith({DocumentStatus? status, String? fileUrl, String? rejectionReason}) =>
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
      case DocumentType.aadhaar:
        return 'Aadhaar Card';
      case DocumentType.pan:
        return 'PAN Card';
      case DocumentType.drivingLicense:
        return 'Driving License';
      case DocumentType.vehicleRc:
        return 'Vehicle RC';
      case DocumentType.vehicleInsurance:
        return 'Insurance';
      case DocumentType.vehiclePhoto:
        return 'Vehicle Photo';
      case DocumentType.bankProof:
        return 'Bank Proof';
    }
  }

  bool get isOptional => this == DocumentType.pan;

  IconData get icon {
    switch (this) {
      case DocumentType.profilePhoto:
        return LucideIcons.userCircle;
      case DocumentType.aadhaar:
        return LucideIcons.fingerprint;
      case DocumentType.pan:
        return LucideIcons.contact;
      case DocumentType.drivingLicense:
        return LucideIcons.creditCard;
      case DocumentType.vehicleRc:
        return LucideIcons.car;
      case DocumentType.vehicleInsurance:
        return LucideIcons.shieldCheck;
      case DocumentType.vehiclePhoto:
        return LucideIcons.camera;
      case DocumentType.bankProof:
        return LucideIcons.landmark;
    }
  }
}
