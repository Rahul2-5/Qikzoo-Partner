import 'package:equatable/equatable.dart';

enum Gender { male, female, other }

enum Relation { father, mother, brother, other }

class PersonalInfoModel extends Equatable {
  final String fullName;
  final DateTime dateOfBirth;
  final Gender gender;
  final String? email;
  final String emergencyContactName;
  final String emergencyContactNumber;
  final Relation relation;
  final String? relationOther;
  final String? referralCode;

  const PersonalInfoModel({
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.email,
    required this.emergencyContactName,
    required this.emergencyContactNumber,
    required this.relation,
    this.relationOther,
    this.referralCode,
  });

  @override
  List<Object?> get props => [
        fullName,
        dateOfBirth,
        gender,
        email,
        emergencyContactName,
        emergencyContactNumber,
        relation,
        relationOther,
        referralCode,
      ];
}
