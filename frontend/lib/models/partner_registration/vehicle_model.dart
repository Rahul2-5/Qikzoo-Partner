import 'package:equatable/equatable.dart';

enum VehicleType { bike, scooter, bicycle, electricVehicle }

class VehicleModel extends Equatable {
  final VehicleType type;
  final String? registrationNumber;

  const VehicleModel({required this.type, this.registrationNumber});

  @override
  List<Object?> get props => [type, registrationNumber];
}
