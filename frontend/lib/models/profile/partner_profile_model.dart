import 'package:equatable/equatable.dart';

class PartnerProfileModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final String? vehicleType;
  final DateTime joinedDate;

  const PartnerProfileModel({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
    this.vehicleType,
    required this.joinedDate,
  });

  @override
  List<Object?> get props => [id, name, phone, photoUrl, vehicleType, joinedDate];
}
