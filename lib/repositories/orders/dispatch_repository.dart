import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/orders/dispatch_offer_model.dart';
import '../../providers/core/api_providers.dart';

abstract class DispatchRepository {
  /// `GET /rider/dispatch/current` — the rider's single outstanding offer,
  /// or `null` if none. Safe to poll continuously: a rider who isn't
  /// AVAILABLE is never assigned an attempt server-side.
  Future<DispatchOfferModel?> getCurrentOffer();

  /// `POST /rider/dispatch/:attemptId/accept` — on success the backend
  /// creates the RiderOrder; the caller re-fetches it via
  /// RiderOrdersRepository rather than trusting this endpoint's bare
  /// return shape (it isn't the same enriched response `getOne`/`current`
  /// return).
  Future<void> accept(String attemptId);

  /// `POST /rider/dispatch/:attemptId/reject`.
  Future<void> reject(String attemptId);
}

class DioDispatchRepository implements DispatchRepository {
  const DioDispatchRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<DispatchOfferModel?> getCurrentOffer() async {
    final response = await _apiClient
        .get<Map<String, dynamic>>(ApiEndpoints.riderDispatchCurrent);
    final payload = _unwrapNullable(response.data);
    return payload == null ? null : DispatchOfferModel.fromJson(payload);
  }

  @override
  Future<void> accept(String attemptId) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderDispatchAccept(attemptId),
    );
  }

  @override
  Future<void> reject(String attemptId) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderDispatchReject(attemptId),
    );
  }

  Map<String, dynamic>? _unwrapNullable(Map<String, dynamic>? body) {
    if (body == null) return null;
    final nested = body['data'];
    if (nested == null) return null;
    return nested is Map<String, dynamic> ? nested : body;
  }
}

final dispatchRepositoryProvider = Provider<DispatchRepository>(
  (ref) => DioDispatchRepository(apiClient: ref.watch(apiClientProvider)),
);
