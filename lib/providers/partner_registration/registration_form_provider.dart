import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/partner_registration/personal_info_model.dart';
import '../../models/partner_registration/vehicle_model.dart';

/// UI state: in-progress selections across the multi-step registration flow.
class RegistrationFormState {
  final String fullName;
  final String email;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String emergencyContactName;
  final String emergencyContactNumber;
  final Relation? relation;
  final String relationOther;
  final String referralCode;
  final VehicleType? vehicleType;
  final String vehicleNumber;
  final String vehicleModel;
  final String? state;
  final String? city;
  final String? preferredZone;

  static final RegExp _plateRegExp =
      RegExp(r'^[A-Za-z]{2}\s?\d{1,2}\s?[A-Za-z]{1,2}\s?\d{4}$');

  const RegistrationFormState({
    this.fullName = '',
    this.email = '',
    this.dateOfBirth,
    this.gender,
    this.emergencyContactName = '',
    this.emergencyContactNumber = '',
    this.relation,
    this.relationOther = '',
    this.referralCode = '',
    this.vehicleType,
    this.vehicleNumber = '',
    this.vehicleModel = '',
    this.state,
    this.city,
    this.preferredZone,
  });

  bool get isPersonalInfoValid =>
      fullName.trim().isNotEmpty &&
      dateOfBirth != null &&
      gender != null &&
      emergencyContactName.trim().isNotEmpty &&
      emergencyContactNumber.trim().length == 10 &&
      relation != null &&
      (relation != Relation.other || relationOther.trim().isNotEmpty);

  bool get isVehicleDetailsValid {
    if (vehicleType == null || vehicleModel.trim().isEmpty) return false;
    if (vehicleType == VehicleType.bicycle) return true;
    return _plateRegExp.hasMatch(vehicleNumber.trim());
  }

  RegistrationFormState copyWith({
    String? fullName,
    String? email,
    DateTime? dateOfBirth,
    Gender? gender,
    String? emergencyContactName,
    String? emergencyContactNumber,
    Relation? relation,
    String? relationOther,
    String? referralCode,
    VehicleType? vehicleType,
    String? vehicleNumber,
    String? vehicleModel,
    String? state,
    String? city,
    String? preferredZone,
  }) =>
      RegistrationFormState(
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        emergencyContactName: emergencyContactName ?? this.emergencyContactName,
        emergencyContactNumber:
            emergencyContactNumber ?? this.emergencyContactNumber,
        relation: relation ?? this.relation,
        relationOther: relationOther ?? this.relationOther,
        referralCode: referralCode ?? this.referralCode,
        vehicleType: vehicleType ?? this.vehicleType,
        vehicleNumber: vehicleNumber ?? this.vehicleNumber,
        vehicleModel: vehicleModel ?? this.vehicleModel,
        state: state ?? this.state,
        city: city ?? this.city,
        preferredZone: preferredZone ?? this.preferredZone,
      );
}

class RegistrationFormNotifier extends Notifier<RegistrationFormState> {
  @override
  RegistrationFormState build() => const RegistrationFormState();

  void setFullName(String value) => state = state.copyWith(fullName: value);
  void setEmail(String value) => state = state.copyWith(email: value);
  void setDateOfBirth(DateTime value) =>
      state = state.copyWith(dateOfBirth: value);
  void setGender(Gender value) => state = state.copyWith(gender: value);
  void setEmergencyContactName(String value) =>
      state = state.copyWith(emergencyContactName: value);
  void setEmergencyContactNumber(String value) =>
      state = state.copyWith(emergencyContactNumber: value);
  void setRelation(Relation value) => state = state.copyWith(relation: value);
  void setRelationOther(String value) =>
      state = state.copyWith(relationOther: value);
  void setReferralCode(String value) =>
      state = state.copyWith(referralCode: value);
  void setVehicleType(VehicleType value) =>
      state = state.copyWith(vehicleType: value);
  void setVehicleNumber(String value) =>
      state = state.copyWith(vehicleNumber: value);
  void setVehicleModel(String value) =>
      state = state.copyWith(vehicleModel: value);
  void setZone(String state_, String city, {String preferredZone = ''}) =>
      state = state.copyWith(
        state: state_,
        city: city,
        preferredZone: preferredZone,
      );
}

final registrationFormProvider =
    NotifierProvider<RegistrationFormNotifier, RegistrationFormState>(
  RegistrationFormNotifier.new,
);
