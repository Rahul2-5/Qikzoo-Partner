import 'package:equatable/equatable.dart';

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
