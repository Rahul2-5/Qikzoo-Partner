import 'package:equatable/equatable.dart';

enum VehicleType { bike, scooter, bicycle, electricVehicle }

extension VehicleTypeDisplay on VehicleType {
  String get label => switch (this) {
        VehicleType.scooter => 'Bike Partner',
        VehicleType.bicycle => 'Cycle Partner',
        VehicleType.electricVehicle => 'E-Bike Partner',
        VehicleType.bike => 'Bike Partner',
      };

  String get imageAsset => switch (this) {
        VehicleType.scooter => 'assets/images/bike_3d.png',
        VehicleType.bicycle => 'assets/images/cycle_3d.png',
        VehicleType.electricVehicle => 'assets/images/e-bike_3d.png',
        VehicleType.bike => 'assets/images/bike_3d.png',
      };
}

class VehicleModel extends Equatable {
  final VehicleType type;
  final String? registrationNumber;
  final String? model;

  const VehicleModel({
    required this.type,
    this.registrationNumber,
    this.model,
  });

  @override
  List<Object?> get props => [type, registrationNumber, model];
}
