import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/partner_registration/personal_info_model.dart';
import '../../models/partner_registration/vehicle_model.dart';
import '../../models/partner_registration/delivery_zone_model.dart';

abstract class PartnerRegistrationRepository {
  Future<void> savePersonalInfo(PersonalInfoModel info);
  Future<void> saveVehicle(VehicleModel vehicle);
  Future<void> saveDeliveryZone(DeliveryZoneModel zone);
}

class MockPartnerRegistrationRepository implements PartnerRegistrationRepository {
  @override
  Future<void> savePersonalInfo(PersonalInfoModel info) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
  }

  @override
  Future<void> saveVehicle(VehicleModel vehicle) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
  }

  @override
  Future<void> saveDeliveryZone(DeliveryZoneModel zone) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
  }
}

final partnerRegistrationRepositoryProvider =
    Provider<PartnerRegistrationRepository>((ref) => MockPartnerRegistrationRepository());
