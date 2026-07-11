import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/partner_registration/vehicle_model.dart';

void main() {
  group('VehicleType display', () {
    test('scooter and bike map to Bike Partner / bike_3d.png', () {
      expect(VehicleType.scooter.label, 'Bike Partner');
      expect(VehicleType.scooter.imageAsset, 'assets/images/bike_3d.png');
      expect(VehicleType.bike.label, 'Bike Partner');
      expect(VehicleType.bike.imageAsset, 'assets/images/bike_3d.png');
    });

    test('bicycle maps to Cycle Partner / cycle_3d.png', () {
      expect(VehicleType.bicycle.label, 'Cycle Partner');
      expect(VehicleType.bicycle.imageAsset, 'assets/images/cycle_3d.png');
    });

    test('electricVehicle maps to E-Bike Partner / e-bike_3d.png', () {
      expect(VehicleType.electricVehicle.label, 'E-Bike Partner');
      expect(VehicleType.electricVehicle.imageAsset,
          'assets/images/e-bike_3d.png');
    });
  });

  group('VehicleModel', () {
    test('carries an optional model field', () {
      const vehicle = VehicleModel(
        type: VehicleType.scooter,
        registrationNumber: 'MH01AB1234',
        model: 'Honda Shine',
      );
      expect(vehicle.model, 'Honda Shine');
      expect(
        vehicle,
        const VehicleModel(
          type: VehicleType.scooter,
          registrationNumber: 'MH01AB1234',
          model: 'Honda Shine',
        ),
      );
    });
  });
}
