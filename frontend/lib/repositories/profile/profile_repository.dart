import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../../models/partner_registration/personal_info_model.dart';
import '../../models/profile/partner_profile_model.dart';
import '../../models/profile/rating_model.dart';
import '../../providers/core/api_providers.dart';

abstract class ProfileRepository {
  Future<PartnerProfileModel> getProfile();
  Future<RatingModel> getRating();

  /// Updates the rider's own personal details (name/email/DOB/gender) —
  /// `PATCH /rider/profile`. Throws [ApiException] (403) if the PROFILE
  /// section is currently locked by onboarding review state.
  Future<PartnerProfileModel> updatePersonalDetails({
    required String name,
    String? email,
    required DateTime dateOfBirth,
    required Gender gender,
  });

  /// Uploads/replaces the rider's profile photo — `POST /rider/profile/photo`
  /// (multipart). [onSendProgress] reports raw bytes sent so callers can
  /// show upload progress; [cancelToken] allows the caller to cancel an
  /// in-flight upload.
  Future<PartnerProfileModel> uploadProfilePhoto(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  });
}

class MockProfileRepository implements ProfileRepository {
  PartnerProfileModel _current = PartnerProfileModel(
    id: 'partner_mock_001',
    name: 'Ankit Verma',
    phone: '9876543210',
    vehicleType: 'Bike',
    joinedDate: DateTime(2026, 3, 12),
  );

  @override
  Future<PartnerProfileModel> getProfile() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return _current;
  }

  @override
  Future<RatingModel> getRating() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return const RatingModel(average: 4.7, totalRatings: 212);
  }

  @override
  Future<PartnerProfileModel> updatePersonalDetails({
    required String name,
    String? email,
    required DateTime dateOfBirth,
    required Gender gender,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    _current = PartnerProfileModel(
      id: _current.id,
      name: name,
      phone: _current.phone,
      photoUrl: _current.photoUrl,
      vehicleType: _current.vehicleType,
      joinedDate: _current.joinedDate,
      email: email,
      dateOfBirth: dateOfBirth,
      gender: gender,
    );
    return _current;
  }

  @override
  Future<PartnerProfileModel> uploadProfilePhoto(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    onSendProgress?.call(1, 1);
    _current = PartnerProfileModel(
      id: _current.id,
      name: _current.name,
      phone: _current.phone,
      photoUrl: file.path,
      vehicleType: _current.vehicleType,
      joinedDate: _current.joinedDate,
      email: _current.email,
      dateOfBirth: _current.dateOfBirth,
      gender: _current.gender,
    );
    return _current;
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
    return _parseProfile(payload);
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

  @override
  Future<PartnerProfileModel> updatePersonalDetails({
    required String name,
    String? email,
    required DateTime dateOfBirth,
    required Gender gender,
  }) async {
    final trimmedEmail = email?.trim();
    final response = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.riderProfile,
      data: {
        'name': name.trim(),
        if (trimmedEmail != null && trimmedEmail.isNotEmpty)
          'email': trimmedEmail,
        'dateOfBirth': _isoDate(dateOfBirth),
        'gender': _genderToBackend(gender),
      },
    );
    return _parseProfile(_unwrap(response.data));
  }

  @override
  Future<PartnerProfileModel> uploadProfilePhoto(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'profile-photo.jpg';
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderProfilePhoto,
      data: formData,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
    return _parseProfile(_unwrap(response.data));
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.riderProfile,
    );
    return _unwrap(response.data);
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    final nested = body?['data'];
    final payload = nested is Map<String, dynamic> ? nested : body;
    return payload ?? const {};
  }

  PartnerProfileModel _parseProfile(Map<String, dynamic> payload) {
    return PartnerProfileModel(
      id: _readString(payload, ['id']) ?? '',
      name: _readString(payload, ['name']) ?? '',
      phone: _readString(payload, ['phone']) ?? '',
      photoUrl: _readString(payload, ['profilePhotoUrl']),
      joinedDate: _readDateTime(payload, ['createdAt']) ?? DateTime.now(),
      email: _readString(payload, ['email']),
      dateOfBirth: _readDateTime(payload, ['dateOfBirth']),
      gender: _genderFromBackend(payload['gender']),
    );
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

  String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _genderToBackend(Gender gender) => switch (gender) {
        Gender.male => 'MALE',
        Gender.female => 'FEMALE',
        Gender.other => 'OTHER',
      };

  /// Backend also allows `PREFER_NOT_TO_SAY` (not offered by this app's
  /// 3-option selector); folded into [Gender.other] so an account edited
  /// elsewhere (e.g. admin panel) still displays instead of showing blank.
  Gender? _genderFromBackend(Object? value) {
    if (value is! String) return null;
    return switch (value) {
      'MALE' => Gender.male,
      'FEMALE' => Gender.female,
      'OTHER' || 'PREFER_NOT_TO_SAY' => Gender.other,
      _ => null,
    };
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => DioProfileRepository(apiClient: ref.watch(apiClientProvider)),
);
