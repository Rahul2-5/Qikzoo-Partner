import 'package:equatable/equatable.dart';

import '../partner_registration/personal_info_model.dart';

class PartnerProfileModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final String? vehicleType;
  final DateTime joinedDate;
  final String? email;
  final DateTime? dateOfBirth;
  final Gender? gender;

  /// Single residential address on file — backend (`Rider` model) stores
  /// exactly one address, not a current/permanent pair.
  final String? addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String? city;
  final String? state;
  final String? pincode;
  final double? addressLat;
  final double? addressLng;

  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const PartnerProfileModel({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
    this.vehicleType,
    required this.joinedDate,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.addressLine1,
    this.addressLine2,
    this.landmark,
    this.city,
    this.state,
    this.pincode,
    this.addressLat,
    this.addressLng,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  /// Mirrors the backend's own `isProfileSectionComplete` personal-fields
  /// half exactly (`rider-onboarding-completion.ts`), used to tell whether
  /// the rider still belongs on Personal Details before Address, since the
  /// backend only exposes one combined "PROFILE" section for both.
  bool get hasCompletePersonalDetails =>
      name.trim().isNotEmpty && dateOfBirth != null && photoUrl != null;

  /// Mirrors the backend's own `isProfileSectionComplete` address-fields
  /// half exactly.
  bool get hasCompleteAddress =>
      (addressLine1?.trim().isNotEmpty ?? false) &&
      (city?.trim().isNotEmpty ?? false) &&
      (state?.trim().isNotEmpty ?? false) &&
      (pincode?.trim().isNotEmpty ?? false);

  /// Mirrors the backend's own `isEmergencyContactSectionComplete` exactly.
  bool get hasCompleteEmergencyContact =>
      (emergencyContactName?.trim().isNotEmpty ?? false) &&
      (emergencyContactPhone?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        photoUrl,
        vehicleType,
        joinedDate,
        email,
        dateOfBirth,
        gender,
        addressLine1,
        addressLine2,
        landmark,
        city,
        state,
        pincode,
        addressLat,
        addressLng,
        emergencyContactName,
        emergencyContactPhone,
      ];
}
