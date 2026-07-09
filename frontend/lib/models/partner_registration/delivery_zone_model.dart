import 'package:equatable/equatable.dart';

class DeliveryZoneModel extends Equatable {
  final String state;
  final String city;
  final String preferredZone;

  const DeliveryZoneModel({required this.state, required this.city, required this.preferredZone});

  @override
  List<Object?> get props => [state, city, preferredZone];
}
