import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/partner_registration/vehicle_model.dart';

/// UI state: in-progress selections across the multi-step registration flow.
class RegistrationFormState {
  final String fullName;
  final VehicleType? vehicleType;
  final String? state;
  final String? city;

  const RegistrationFormState({
    this.fullName = '',
    this.vehicleType,
    this.state,
    this.city,
  });

  RegistrationFormState copyWith({
    String? fullName,
    VehicleType? vehicleType,
    String? state,
    String? city,
  }) =>
      RegistrationFormState(
        fullName: fullName ?? this.fullName,
        vehicleType: vehicleType ?? this.vehicleType,
        state: state ?? this.state,
        city: city ?? this.city,
      );
}

class RegistrationFormNotifier extends Notifier<RegistrationFormState> {
  @override
  RegistrationFormState build() => const RegistrationFormState();

  void setFullName(String value) => state = state.copyWith(fullName: value);
  void setVehicleType(VehicleType value) => state = state.copyWith(vehicleType: value);
  void setZone(String state_, String city) => state = state.copyWith(state: state_, city: city);
}

final registrationFormProvider =
    NotifierProvider<RegistrationFormNotifier, RegistrationFormState>(
  RegistrationFormNotifier.new,
);
