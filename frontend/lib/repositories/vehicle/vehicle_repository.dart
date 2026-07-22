import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../../models/vehicle/rider_vehicle_model.dart';
import '../../providers/core/api_providers.dart';

abstract class VehicleRepository {
  /// `GET /rider/vehicles` — every vehicle ever registered by this rider,
  /// most recent first.
  Future<List<RiderVehicleModel>> listVehicles();

  /// `POST /rider/vehicles` — always registers a NEW vehicle row (there is
  /// no update endpoint for an existing one). Throws [ApiException] (409)
  /// if this registration number is already on file.
  Future<RiderVehicleModel> createVehicle({
    required VehicleType type,
    required String registrationNumber,
    String? insuranceNumber,
    DateTime? insuranceExpiry,
    String? rcNumber,
  });

  /// `PATCH /rider/vehicles/:vehicleId/activate` — only valid on an
  /// APPROVED vehicle.
  Future<RiderVehicleModel> setActive(String vehicleId);

  /// `POST /rider/vehicles/:vehicleId/documents/insurance` (multipart).
  Future<RiderVehicleModel> uploadInsuranceDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  });

  /// `POST /rider/vehicles/:vehicleId/documents/rc` (multipart).
  Future<RiderVehicleModel> uploadRcDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  });
}

class MockVehicleRepository implements VehicleRepository {
  final List<RiderVehicleModel> _vehicles = [];
  int _nextId = 1;

  @override
  Future<List<RiderVehicleModel>> listVehicles() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return List.unmodifiable(_vehicles.reversed);
  }

  @override
  Future<RiderVehicleModel> createVehicle({
    required VehicleType type,
    required String registrationNumber,
    String? insuranceNumber,
    DateTime? insuranceExpiry,
    String? rcNumber,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    final vehicle = RiderVehicleModel(
      id: 'vehicle_${_nextId++}',
      type: type,
      registrationNumber: registrationNumber,
      insuranceNumber: insuranceNumber,
      insuranceExpiry: insuranceExpiry,
      rcNumber: rcNumber,
      isActive: true,
    );
    _vehicles.add(vehicle);
    return vehicle;
  }

  @override
  Future<RiderVehicleModel> setActive(String vehicleId) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    final updated = _vehicles[index];
    for (var i = 0; i < _vehicles.length; i++) {
      _vehicles[i] = _copyWith(_vehicles[i], isActive: i == index);
    }
    return _vehicles[index].isActive ? _vehicles[index] : updated;
  }

  @override
  Future<RiderVehicleModel> uploadInsuranceDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    onSendProgress?.call(1, 1);
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    _vehicles[index] =
        _copyWith(_vehicles[index], insuranceDocumentUrl: file.path);
    return _vehicles[index];
  }

  @override
  Future<RiderVehicleModel> uploadRcDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    onSendProgress?.call(1, 1);
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    _vehicles[index] = _copyWith(_vehicles[index], rcDocumentUrl: file.path);
    return _vehicles[index];
  }

  RiderVehicleModel _copyWith(
    RiderVehicleModel v, {
    bool? isActive,
    String? insuranceDocumentUrl,
    String? rcDocumentUrl,
  }) =>
      RiderVehicleModel(
        id: v.id,
        type: v.type,
        registrationNumber: v.registrationNumber,
        insuranceNumber: v.insuranceNumber,
        insuranceExpiry: v.insuranceExpiry,
        insuranceDocumentUrl: insuranceDocumentUrl ?? v.insuranceDocumentUrl,
        rcNumber: v.rcNumber,
        rcDocumentUrl: rcDocumentUrl ?? v.rcDocumentUrl,
        isActive: isActive ?? v.isActive,
        status: v.status,
        rejectionReason: v.rejectionReason,
      );
}

class DioVehicleRepository implements VehicleRepository {
  const DioVehicleRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<RiderVehicleModel>> listVehicles() async {
    final response =
        await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.riderVehicles);
    final payload = response.data?['data'];
    if (payload is! List) return const [];
    return payload
        .whereType<Map<String, dynamic>>()
        .map(RiderVehicleModel.fromJson)
        .toList();
  }

  @override
  Future<RiderVehicleModel> createVehicle({
    required VehicleType type,
    required String registrationNumber,
    String? insuranceNumber,
    DateTime? insuranceExpiry,
    String? rcNumber,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderVehicles,
      data: {
        'type': type.backendValue,
        'registrationNumber': registrationNumber.trim(),
        if (insuranceNumber != null && insuranceNumber.trim().isNotEmpty)
          'insuranceNumber': insuranceNumber.trim(),
        if (insuranceExpiry != null)
          'insuranceExpiry': _isoDate(insuranceExpiry),
        if (rcNumber != null && rcNumber.trim().isNotEmpty)
          'rcNumber': rcNumber.trim(),
      },
    );
    return RiderVehicleModel.fromJson(_unwrap(response.data));
  }

  @override
  Future<RiderVehicleModel> setActive(String vehicleId) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.riderVehicleActivate(vehicleId),
    );
    return RiderVehicleModel.fromJson(_unwrap(response.data));
  }

  @override
  Future<RiderVehicleModel> uploadInsuranceDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      _uploadDocument(
        ApiEndpoints.riderVehicleInsuranceDocument(vehicleId),
        file,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

  @override
  Future<RiderVehicleModel> uploadRcDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      _uploadDocument(
        ApiEndpoints.riderVehicleRcDocument(vehicleId),
        file,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

  Future<RiderVehicleModel> _uploadDocument(
    String path,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final fileName =
        file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'document';
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final response = await _apiClient.post<Map<String, dynamic>>(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
    return RiderVehicleModel.fromJson(_unwrap(response.data));
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    final nested = body?['data'];
    final payload = nested is Map<String, dynamic> ? nested : body;
    return payload ?? const {};
  }

  String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => DioVehicleRepository(apiClient: ref.watch(apiClientProvider)),
);
