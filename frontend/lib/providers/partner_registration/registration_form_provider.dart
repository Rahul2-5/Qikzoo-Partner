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
  final String referralCode;
  final VehicleType? vehicleType;
  final String? state;
  final String? city;

  const RegistrationFormState({
    this.fullName = '',
    this.email = '',
    this.dateOfBirth,
    this.gender,
    this.emergencyContactName = '',
    this.emergencyContactNumber = '',
    this.referralCode = '',
    this.vehicleType,
    this.state,
    this.city,
  });

  bool get isPersonalInfoValid =>
      fullName.trim().isNotEmpty &&
      dateOfBirth != null &&
      gender != null &&
      emergencyContactName.trim().isNotEmpty &&
      emergencyContactNumber.trim().length == 10;

  RegistrationFormState copyWith({
    String? fullName,
    String? email,
    DateTime? dateOfBirth,
    Gender? gender,
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? referralCode,
    VehicleType? vehicleType,
    String? state,
    String? city,
  }) =>
      RegistrationFormState(
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        emergencyContactName: emergencyContactName ?? this.emergencyContactName,
        emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
        referralCode: referralCode ?? this.referralCode,
        vehicleType: vehicleType ?? this.vehicleType,
        state: state ?? this.state,
        city: city ?? this.city,
      );
}

class RegistrationFormNotifier extends Notifier<RegistrationFormState> {
  @override
  RegistrationFormState build() => const RegistrationFormState();

  void setFullName(String value) => state = state.copyWith(fullName: value);
  void setEmail(String value) => state = state.copyWith(email: value);
  void setDateOfBirth(DateTime value) => state = state.copyWith(dateOfBirth: value);
  void setGender(Gender value) => state = state.copyWith(gender: value);
  void setEmergencyContactName(String value) => state = state.copyWith(emergencyContactName: value);
  void setEmergencyContactNumber(String value) => state = state.copyWith(emergencyContactNumber: value);
  void setReferralCode(String value) => state = state.copyWith(referralCode: value);
  void setVehicleType(VehicleType value) => state = state.copyWith(vehicleType: value);
  void setZone(String state_, String city) => state = state.copyWith(state: state_, city: city);
}

final registrationFormProvider =
    NotifierProvider<RegistrationFormNotifier, RegistrationFormState>(
  RegistrationFormNotifier.new,
);
