import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/document_verification/document_model.dart';
import '../../models/kyc/rider_kyc_model.dart';
import '../../models/profile/partner_profile_model.dart';
import '../../models/vehicle/rider_vehicle_model.dart';
import '../kyc/kyc_repository.dart';
import '../profile/profile_repository.dart';
import '../vehicle/vehicle_repository.dart';

abstract class DocumentRepository {
  Future<List<DocumentModel>> getDocuments();
  Future<DocumentModel> uploadDocument(DocumentType type, String filePath);
}

/// Composes real per-document status from [ProfileRepository],
/// [KycRepository] and [VehicleRepository] — there is no single
/// "all documents" endpoint, and no separate document-storage system of
/// its own (no new tables, no new uploads outside those three real APIs).
class RealDocumentRepository implements DocumentRepository {
  const RealDocumentRepository({
    required ProfileRepository profileRepository,
    required KycRepository kycRepository,
    required VehicleRepository vehicleRepository,
  })  : _profile = profileRepository,
        _kyc = kycRepository,
        _vehicle = vehicleRepository;

  final ProfileRepository _profile;
  final KycRepository _kyc;
  final VehicleRepository _vehicle;

  @override
  Future<List<DocumentModel>> getDocuments() async {
    final results = await Future.wait([
      _profile.getProfile(),
      _kyc.getKyc(),
      _vehicle.listVehicles(),
    ]);
    final profile = results[0] as PartnerProfileModel;
    final kyc = results[1] as RiderKycModel?;
    final vehicles = results[2] as List<RiderVehicleModel>;
    final vehicle = _primaryVehicle(vehicles);

    return [
      DocumentModel(
        type: DocumentType.profilePhoto,
        status: profile.photoUrl != null
            ? DocumentStatus.verified
            : DocumentStatus.notUploaded,
        fileUrl: profile.photoUrl,
      ),
      _kycDocument(
        DocumentType.governmentId,
        hasDocument: kyc?.hasGovernmentIdDocument ?? false,
        fileUrl: kyc?.governmentIdDocumentUrl,
        kycStatus: kyc?.status,
        rejectionReason: kyc?.rejectionReason,
      ),
      _kycDocument(
        DocumentType.drivingLicense,
        hasDocument: kyc?.hasDrivingLicenseDocument ?? false,
        fileUrl: kyc?.drivingLicenseDocumentUrl,
        kycStatus: kyc?.status,
        rejectionReason: kyc?.rejectionReason,
      ),
      _vehicleDocument(
        DocumentType.vehicleRc,
        vehicle: vehicle,
        hasDocument: (vehicle?.rcDocumentUrl ?? '').isNotEmpty,
        fileUrl: vehicle?.rcDocumentUrl,
      ),
      _vehicleDocument(
        DocumentType.vehicleInsurance,
        vehicle: vehicle,
        hasDocument: (vehicle?.insuranceDocumentUrl ?? '').isNotEmpty,
        fileUrl: vehicle?.insuranceDocumentUrl,
      ),
      DocumentModel(
        type: DocumentType.bankProof,
        status: (kyc?.hasBankAccountOnFile ?? false)
            ? DocumentStatus.verified
            : DocumentStatus.notUploaded,
      ),
    ];
  }

  @override
  Future<DocumentModel> uploadDocument(DocumentType type, String filePath) async {
    final file = File(filePath);
    switch (type) {
      case DocumentType.profilePhoto:
        final profile = await _profile.uploadProfilePhoto(file);
        return DocumentModel(
          type: type,
          status: DocumentStatus.verified,
          fileUrl: profile.photoUrl,
        );
      case DocumentType.governmentId:
        final kyc = await _kyc.uploadGovernmentIdDocument(file);
        return DocumentModel(
          type: type,
          status: DocumentStatus.pendingVerification,
          fileUrl: kyc.governmentIdDocumentUrl,
        );
      case DocumentType.drivingLicense:
        final kyc = await _kyc.uploadDrivingLicenseDocument(file);
        return DocumentModel(
          type: type,
          status: DocumentStatus.pendingVerification,
          fileUrl: kyc.drivingLicenseDocumentUrl,
        );
      case DocumentType.vehicleRc:
        final vehicle = await _requireVehicle();
        final updated = await _vehicle.uploadRcDocument(vehicle.id, file);
        return DocumentModel(
          type: type,
          status: DocumentStatus.pendingVerification,
          fileUrl: updated.rcDocumentUrl,
        );
      case DocumentType.vehicleInsurance:
        final vehicle = await _requireVehicle();
        final updated = await _vehicle.uploadInsuranceDocument(vehicle.id, file);
        return DocumentModel(
          type: type,
          status: DocumentStatus.pendingVerification,
          fileUrl: updated.insuranceDocumentUrl,
        );
      case DocumentType.bankProof:
        // Bank payout details are text fields on KYC (see Bank Details),
        // not a document upload — there is no real endpoint to send a
        // file to for this type.
        throw StateError(
          'Bank details are entered as text in Bank Details, not uploaded as a document.',
        );
    }
  }

  Future<RiderVehicleModel> _requireVehicle() async {
    final vehicle = _primaryVehicle(await _vehicle.listVehicles());
    if (vehicle == null) {
      throw StateError('Register a vehicle before uploading vehicle documents.');
    }
    return vehicle;
  }

  RiderVehicleModel? _primaryVehicle(List<RiderVehicleModel> vehicles) {
    if (vehicles.isEmpty) return null;
    for (final vehicle in vehicles) {
      if (vehicle.isActive) return vehicle;
    }
    return vehicles.first;
  }

  DocumentModel _kycDocument(
    DocumentType type, {
    required bool hasDocument,
    String? fileUrl,
    KycDocumentStatus? kycStatus,
    String? rejectionReason,
  }) {
    if (!hasDocument) {
      return DocumentModel(type: type, status: DocumentStatus.notUploaded);
    }
    return DocumentModel(
      type: type,
      status: _statusFrom(kycStatus),
      fileUrl: fileUrl,
      rejectionReason: rejectionReason,
    );
  }

  DocumentModel _vehicleDocument(
    DocumentType type, {
    required RiderVehicleModel? vehicle,
    required bool hasDocument,
    String? fileUrl,
  }) {
    if (!hasDocument) {
      return DocumentModel(type: type, status: DocumentStatus.notUploaded);
    }
    return DocumentModel(
      type: type,
      status: _vehicleStatusFrom(vehicle?.status),
      fileUrl: fileUrl,
      rejectionReason: vehicle?.rejectionReason,
    );
  }

  DocumentStatus _statusFrom(KycDocumentStatus? status) => switch (status) {
        KycDocumentStatus.approved => DocumentStatus.verified,
        KycDocumentStatus.rejected => DocumentStatus.rejected,
        _ => DocumentStatus.pendingVerification,
      };

  DocumentStatus _vehicleStatusFrom(VehicleDocumentStatus? status) => switch (status) {
        VehicleDocumentStatus.approved => DocumentStatus.verified,
        VehicleDocumentStatus.rejected => DocumentStatus.rejected,
        _ => DocumentStatus.pendingVerification,
      };
}

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => RealDocumentRepository(
    profileRepository: ref.watch(profileRepositoryProvider),
    kycRepository: ref.watch(kycRepositoryProvider),
    vehicleRepository: ref.watch(vehicleRepositoryProvider),
  ),
);
