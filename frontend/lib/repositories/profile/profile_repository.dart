import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../../models/profile/partner_profile_model.dart';
import '../../models/profile/rating_model.dart';
import '../../providers/core/api_providers.dart';

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

/// `GET /rider/profile` returns the rider's own account row (id, name,
/// phone, profilePhotoUrl, createdAt, rating, totalDeliveries, ...) — it
/// does not include vehicle type, which lives on a separate RiderVehicle
/// record, so [PartnerProfileModel.vehicleType] is left null here.
class DioProfileRepository implements ProfileRepository {
  const DioProfileRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<PartnerProfileModel> getProfile() async {
    final payload = await _fetchProfile();
    return PartnerProfileModel(
      id: _readString(payload, ['id']) ?? '',
      name: _readString(payload, ['name']) ?? '',
      phone: _readString(payload, ['phone']) ?? '',
      photoUrl: _readString(payload, ['profilePhotoUrl']),
      joinedDate: _readDateTime(payload, ['createdAt']) ?? DateTime.now(),
    );
  }

  @override
  Future<RatingModel> getRating() async {
    final payload = await _fetchProfile();
    final rating = payload['rating'];
    final totalDeliveries = payload['totalDeliveries'];
    return RatingModel(
      average: rating is num ? rating.toDouble() : 0,
      totalRatings: totalDeliveries is num ? totalDeliveries.toInt() : 0,
    );
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.riderProfile,
    );
    final body = response.data;
    final nested = body?['data'];
    final payload = nested is Map<String, dynamic> ? nested : body;
    return payload ?? const {};
  }

  String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  DateTime? _readDateTime(Map<String, dynamic> data, List<String> keys) {
    final value = _readString(data, keys);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => DioProfileRepository(apiClient: ref.watch(apiClientProvider)),
);
