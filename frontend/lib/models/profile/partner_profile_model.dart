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
  });

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
      ];
}
