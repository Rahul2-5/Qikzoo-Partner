import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/profile/partner_profile_model.dart';
import '../../models/profile/rating_model.dart';

abstract class ProfileRepository {
  Future<PartnerProfileModel> getProfile();
  Future<RatingModel> getRating();
}

class MockProfileRepository implements ProfileRepository {
  @override
  Future<PartnerProfileModel> getProfile() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return PartnerProfileModel(
      id: 'partner_mock_001',
      name: 'Ankit Verma',
      phone: '9876543210',
      vehicleType: 'Bike',
      joinedDate: DateTime(2026, 3, 12),
    );
  }

  @override
  Future<RatingModel> getRating() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return const RatingModel(average: 4.7, totalRatings: 212);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => MockProfileRepository());
