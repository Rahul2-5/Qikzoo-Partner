import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../../models/kyc/rider_kyc_model.dart';
import '../../providers/core/api_providers.dart';

abstract class KycRepository {
  /// `GET /rider/kyc` — returns null when the rider hasn't submitted or
  /// uploaded anything yet (no `RiderKyc` row exists).
  Future<RiderKycModel?> getKyc();

  /// Submits/updates government ID, driving licence and bank text fields —
  /// `PUT /rider/kyc`. Only send the fields that actually changed; the
  /// backend persists whatever keys are present in the body and leaves the
  /// rest untouched, but re-sending unchanged data still resets `status`
  /// back to PENDING and clears any prior rejection reason, so avoid
  /// calling this with an unchanged payload.
  Future<RiderKycModel> submit({
    GovernmentIdType? governmentIdType,
    String? governmentIdNumber,
    String? drivingLicenseNumber,
    DateTime? drivingLicenseExpiry,
    String? bankAccountHolderName,
    String? bankAccountNumber,
    String? confirmBankAccountNumber,
    String? bankIfsc,
    String? bankName,
  });

  /// `POST /rider/kyc/documents/government-id` (multipart).
  Future<RiderKycModel> uploadGovernmentIdDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  });

  /// `POST /rider/kyc/documents/driving-license` (multipart).
  Future<RiderKycModel> uploadDrivingLicenseDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  });
}

class MockKycRepository implements KycRepository {
  RiderKycModel? _current;

  @override
  Future<RiderKycModel?> getKyc() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return _current;
  }

  @override
  Future<RiderKycModel> submit({
    GovernmentIdType? governmentIdType,
    String? governmentIdNumber,
    String? drivingLicenseNumber,
    DateTime? drivingLicenseExpiry,
    String? bankAccountHolderName,
    String? bankAccountNumber,
    String? confirmBankAccountNumber,
    String? bankIfsc,
    String? bankName,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    final c = _current;
    _current = RiderKycModel(
      governmentIdType: governmentIdType ?? c?.governmentIdType,
      governmentIdNumber: governmentIdNumber ?? c?.governmentIdNumber,
      governmentIdDocumentUrl: c?.governmentIdDocumentUrl,
      drivingLicenseNumber: drivingLicenseNumber ?? c?.drivingLicenseNumber,
      drivingLicenseExpiry: drivingLicenseExpiry ?? c?.drivingLicenseExpiry,
      drivingLicenseDocumentUrl: c?.drivingLicenseDocumentUrl,
      bankAccountHolderName: bankAccountHolderName ?? c?.bankAccountHolderName,
      bankAccountNumberMasked: bankAccountNumber != null
          ? '•••• ${bankAccountNumber.substring(bankAccountNumber.length - 4)}'
          : c?.bankAccountNumberMasked,
      bankIfsc: bankIfsc ?? c?.bankIfsc,
      bankName: bankName ?? c?.bankName,
      status: KycDocumentStatus.pending,
    );
    return _current!;
  }

  @override
  Future<RiderKycModel> uploadGovernmentIdDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    onSendProgress?.call(1, 1);
    final c = _current;
    _current = RiderKycModel(
      governmentIdType: c?.governmentIdType,
      governmentIdNumber: c?.governmentIdNumber,
      governmentIdDocumentUrl: file.path,
      drivingLicenseNumber: c?.drivingLicenseNumber,
      drivingLicenseExpiry: c?.drivingLicenseExpiry,
      drivingLicenseDocumentUrl: c?.drivingLicenseDocumentUrl,
      bankAccountHolderName: c?.bankAccountHolderName,
      bankAccountNumberMasked: c?.bankAccountNumberMasked,
      bankIfsc: c?.bankIfsc,
      bankName: c?.bankName,
      status: KycDocumentStatus.pending,
    );
    return _current!;
  }

  @override
  Future<RiderKycModel> uploadDrivingLicenseDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    onSendProgress?.call(1, 1);
    final c = _current;
    _current = RiderKycModel(
      governmentIdType: c?.governmentIdType,
      governmentIdNumber: c?.governmentIdNumber,
      governmentIdDocumentUrl: c?.governmentIdDocumentUrl,
      drivingLicenseNumber: c?.drivingLicenseNumber,
      drivingLicenseExpiry: c?.drivingLicenseExpiry,
      drivingLicenseDocumentUrl: file.path,
      bankAccountHolderName: c?.bankAccountHolderName,
      bankAccountNumberMasked: c?.bankAccountNumberMasked,
      bankIfsc: c?.bankIfsc,
      bankName: c?.bankName,
      status: KycDocumentStatus.pending,
    );
    return _current!;
  }
}

class DioKycRepository implements KycRepository {
  const DioKycRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<RiderKycModel?> getKyc() async {
    final response =
        await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.riderKyc);
    final payload = _unwrapNullable(response.data);
    return payload == null ? null : RiderKycModel.fromJson(payload);
  }

  @override
  Future<RiderKycModel> submit({
    GovernmentIdType? governmentIdType,
    String? governmentIdNumber,
    String? drivingLicenseNumber,
    DateTime? drivingLicenseExpiry,
    String? bankAccountHolderName,
    String? bankAccountNumber,
    String? confirmBankAccountNumber,
    String? bankIfsc,
    String? bankName,
  }) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.riderKyc,
      data: {
        if (governmentIdType != null)
          'governmentIdType': governmentIdType.backendValue,
        if (governmentIdNumber != null)
          'governmentIdNumber': governmentIdNumber,
        if (drivingLicenseNumber != null)
          'drivingLicenseNumber': drivingLicenseNumber,
        if (drivingLicenseExpiry != null)
          'drivingLicenseExpiry': _isoDate(drivingLicenseExpiry),
        if (bankAccountHolderName != null)
          'bankAccountHolderName': bankAccountHolderName,
        if (bankAccountNumber != null)
          'bankAccountNumber': bankAccountNumber,
        if (confirmBankAccountNumber != null)
          'confirmBankAccountNumber': confirmBankAccountNumber,
        if (bankIfsc != null) 'bankIfsc': bankIfsc,
        if (bankName != null) 'bankName': bankName,
      },
    );
    return RiderKycModel.fromJson(_unwrap(response.data));
  }

  @override
  Future<RiderKycModel> uploadGovernmentIdDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      _uploadDocument(
        ApiEndpoints.riderKycGovernmentIdDocument,
        file,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

  @override
  Future<RiderKycModel> uploadDrivingLicenseDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      _uploadDocument(
        ApiEndpoints.riderKycDrivingLicenseDocument,
        file,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

  Future<RiderKycModel> _uploadDocument(
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
    return RiderKycModel.fromJson(_unwrap(response.data));
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    final nested = body?['data'];
    final payload = nested is Map<String, dynamic> ? nested : body;
    return payload ?? const {};
  }

  Map<String, dynamic>? _unwrapNullable(Map<String, dynamic>? body) {
    final nested = body?['data'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested == null) return null;
    return body;
  }

  String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

final kycRepositoryProvider = Provider<KycRepository>(
  (ref) => DioKycRepository(apiClient: ref.watch(apiClientProvider)),
);
