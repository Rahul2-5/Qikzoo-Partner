import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/partner_registration/vehicle_model.dart';
import 'package:delivery_partner_app/providers/partner_registration/registration_form_provider.dart';

void main() {
  group('vehicle details validity', () {
    test('invalid with empty model, regardless of type', () {
      const state = RegistrationFormState(
        vehicleType: VehicleType.scooter,
        vehicleNumber: 'MH01AB1234',
        vehicleModel: '',
      );
      expect(state.isVehicleDetailsValid, isFalse);
    });

    test('bicycle only needs a model, number is ignored', () {
      const state = RegistrationFormState(
        vehicleType: VehicleType.bicycle,
        vehicleNumber: '',
        vehicleModel: 'Hero Sprint',
      );
      expect(state.isVehicleDetailsValid, isTrue);
    });

    test('scooter needs a model and a well-formed number', () {
      const invalid = RegistrationFormState(
        vehicleType: VehicleType.scooter,
        vehicleNumber: 'not-a-plate',
        vehicleModel: 'Honda Shine',
      );
      expect(invalid.isVehicleDetailsValid, isFalse);

      const valid = RegistrationFormState(
        vehicleType: VehicleType.scooter,
        vehicleNumber: 'MH 01 AB 1234',
        vehicleModel: 'Honda Shine',
      );
      expect(valid.isVehicleDetailsValid, isTrue);
    });

    test('electricVehicle needs a model and a well-formed number', () {
      const state = RegistrationFormState(
        vehicleType: VehicleType.electricVehicle,
        vehicleNumber: 'KA05MZ9021',
        vehicleModel: 'Ather 450X',
      );
      expect(state.isVehicleDetailsValid, isTrue);
    });

    test('invalid when vehicleType is null', () {
      const state = RegistrationFormState(
        vehicleNumber: 'MH01AB1234',
        vehicleModel: 'Honda Shine',
      );
      expect(state.isVehicleDetailsValid, isFalse);
    });
  });

  group('RegistrationFormNotifier vehicle detail setters', () {
    test('setVehicleNumber and setVehicleModel update state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(registrationFormProvider.notifier);

      notifier.setVehicleNumber('MH01AB1234');
      notifier.setVehicleModel('Honda Shine');

      final state = container.read(registrationFormProvider);
      expect(state.vehicleNumber, 'MH01AB1234');
      expect(state.vehicleModel, 'Honda Shine');
    });
  });
}
