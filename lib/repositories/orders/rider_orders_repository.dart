import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/orders/order_history_page_model.dart';
import '../../models/orders/delivery_completion_model.dart';
import '../../models/orders/delivery_payment_session.dart';
import '../../models/orders/rider_order_model.dart';
import '../../providers/core/api_providers.dart';

abstract class RiderOrdersRepository {
  /// `GET /rider/orders/current` — every not-yet-delivered/cancelled order
  /// this rider holds. In practice at most one (a rider can only accept one
  /// dispatch offer at a time), but the backend returns a list, so the
  /// caller decides how to treat more than one.
  Future<List<RiderOrderModel>> getCurrent();

  /// `GET /rider/orders/:id` — the only response that includes the full
  /// RestaurantOrder status timeline.
  Future<RiderOrderModel> getOne(String riderOrderId);

  /// `GET /rider/orders/history?status=&page=&pageSize=`.
  Future<OrderHistoryPageModel> getHistory({
    required OrderHistoryFilter filter,
    required int page,
    required int pageSize,
  });

  /// `POST /rider/orders/:id/arrived` — now server-side GPS-validated;
  /// the backend either transitions to ARRIVED_AT_RESTAURANT or returns a
  /// 400 the caller surfaces verbatim (see `ActiveOrderScreen._run`).
  /// There is no rider-initiated pickup-confirmation call after this: once
  /// the restaurant staff verify the pickup OTP on their own dashboard,
  /// the backend transitions the RiderOrder straight to PICKED_UP, which
  /// this app only ever observes via its existing polling.
  Future<void> markArrived(String riderOrderId);

  /// `POST /rider/orders/:id/scan-pickup-qr`
  Future<void> scanPickupQr(String riderOrderId, String token);

  /// `POST /rider/orders/:id/pickup-success`
  Future<void> pickupSuccess(String riderOrderId);

  /// `POST /rider/orders/:id/start-delivery`.
  Future<void> startDelivery(String riderOrderId);

  /// `POST /rider/orders/:id/complete-delivery` — sends the verification OTP code
  Future<DeliveryPaymentSession> createPaymentSession(String riderOrderId);

  Future<DeliveryPaymentSession> getPaymentSession(String riderOrderId);

  Future<void> collectCash(String riderOrderId);

  Future<DeliveryCompletionModel> completeDelivery(String riderOrderId);

  /// `POST /rider/orders/:id/cancel`.
  Future<void> cancel(String riderOrderId, String reason);
}

class DioRiderOrdersRepository implements RiderOrdersRepository {
  const DioRiderOrdersRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<RiderOrderModel>> getCurrent() async {
    final response = await _apiClient
        .get<Map<String, dynamic>>(ApiEndpoints.riderOrdersCurrent);
    final payload = _unwrapList(response.data);
    return payload.map(RiderOrderModel.fromJson).toList();
  }

  @override
  Future<RiderOrderModel> getOne(String riderOrderId) async {
    final response = await _apiClient
        .get<Map<String, dynamic>>(ApiEndpoints.riderOrderDetail(riderOrderId));
    return RiderOrderModel.fromJson(_unwrap(response.data));
  }

  @override
  Future<OrderHistoryPageModel> getHistory({
    required OrderHistoryFilter filter,
    required int page,
    required int pageSize,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.riderOrdersHistory,
      queryParameters: {
        'status': filter.backendValue,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return OrderHistoryPageModel.fromJson(_unwrap(response.data));
  }

  @override
  Future<void> markArrived(String riderOrderId) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderOrderArrived(riderOrderId),
    );
  }

  @override
  Future<void> scanPickupQr(String riderOrderId, String token) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderOrderScanPickupQr(riderOrderId),
      data: {'token': token},
    );
  }

  @override
  Future<void> pickupSuccess(String riderOrderId) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderOrderPickupSuccess(riderOrderId),
    );
  }

  @override
  Future<void> startDelivery(String riderOrderId) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderOrderStartDelivery(riderOrderId),
    );
  }

  @override
  Future<DeliveryPaymentSession> createPaymentSession(
    String riderOrderId,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderOrderPaymentSession(riderOrderId),
    );
    return DeliveryPaymentSession.fromJson(
      _unwrap(response.data),
      riderOrderId: riderOrderId,
    );
  }

  @override
  Future<DeliveryPaymentSession> getPaymentSession(
    String riderOrderId,
  ) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.riderOrderPaymentSession(riderOrderId),
    );
    return DeliveryPaymentSession.fromJson(
      _unwrap(response.data),
      riderOrderId: riderOrderId,
    );
  }

  @override
  Future<void> collectCash(String riderOrderId) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderOrderCollectCash(riderOrderId),
    );
  }

  @override
  Future<DeliveryCompletionModel> completeDelivery(
    String riderOrderId,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderOrderCompleteDelivery(riderOrderId),
    );
    return DeliveryCompletionModel.fromJson(_unwrap(response.data));
  }

  @override
  Future<void> cancel(String riderOrderId, String reason) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderOrderCancel(riderOrderId),
      data: {'reason': reason},
    );
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    final nested = body?['data'];
    final payload = nested is Map<String, dynamic> ? nested : body;
    return payload ?? const {};
  }

  List<Map<String, dynamic>> _unwrapList(Map<String, dynamic>? body) {
    final nested = body?['data'];
    final payload = nested ?? body;
    if (payload is! List) return const [];
    return payload.whereType<Map<String, dynamic>>().toList();
  }
}

final riderOrdersRepositoryProvider = Provider<RiderOrdersRepository>(
  (ref) => DioRiderOrdersRepository(apiClient: ref.watch(apiClientProvider)),
);
