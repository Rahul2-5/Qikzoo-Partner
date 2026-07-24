import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/partner_registration/vehicle_model.dart';
import '../../repositories/partner_registration/partner_registration_repository.dart';

class VehicleDetailsNotifier extends AsyncNotifier<VehicleModel?> {
  @override
  Future<VehicleModel?> build() =>
      ref.watch(partnerRegistrationRepositoryProvider).getVehicle();

  Future<void> save(VehicleModel vehicle) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(partnerRegistrationRepositoryProvider)
          .saveVehicle(vehicle);
      return vehicle;
    });
  }
}

final vehicleDetailsProvider =
    AsyncNotifierProvider<VehicleDetailsNotifier, VehicleModel?>(
  VehicleDetailsNotifier.new,
);
