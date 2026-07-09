import 'package:equatable/equatable.dart';

enum Gender { male, female, other }

class PersonalInfoModel extends Equatable {
  final String fullName;
  final DateTime dateOfBirth;
  final Gender gender;
  final String? email;
  final String emergencyContactName;
  final String emergencyContactNumber;
  final String? referralCode;

  const PersonalInfoModel({
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.email,
    required this.emergencyContactName,
    required this.emergencyContactNumber,
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
        referralCode,
      ];
}
