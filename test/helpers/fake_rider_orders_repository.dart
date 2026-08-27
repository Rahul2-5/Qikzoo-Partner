import 'dart:async';

import 'package:delivery_partner_app/models/orders/delivery_completion_model.dart';
import 'package:delivery_partner_app/models/orders/delivery_payment_session.dart';
import 'package:delivery_partner_app/models/orders/order_history_page_model.dart';
import 'package:delivery_partner_app/models/orders/rider_order_model.dart';
import 'package:delivery_partner_app/repositories/orders/rider_orders_repository.dart';

class FakeRiderOrdersRepository implements RiderOrdersRepository {
  int getCurrentCalls = 0;
  int getPaymentSessionCalls = 0;
  int createPaymentSessionCalls = 0;
  int completeDeliveryCalls = 0;

  final List<Object> paymentStatusResponses = [];
  final List<List<RiderOrderModel>> currentResponses = [];
  DeliveryPaymentSession? createdSession;
  Completer<DeliveryPaymentSession>? createCompleter;
  DeliveryCompletionModel completion = DeliveryCompletionModel(
    riderOrderId: 'rider-order-1',
    deliveredAt: DateTime(2026, 8, 22, 18, 30),
    earningsPaise: 5500,
  );

  Object? _lastPaymentResponse;
  List<RiderOrderModel> _lastCurrent = const [];

  @override
  Future<List<RiderOrderModel>> getCurrent() async {
    getCurrentCalls++;
    if (currentResponses.isNotEmpty) {
      _lastCurrent = currentResponses.removeAt(0);
    }
    return _lastCurrent;
  }

  @override
  Future<DeliveryPaymentSession> getPaymentSession(
    String riderOrderId,
  ) async {
    getPaymentSessionCalls++;
    if (paymentStatusResponses.isNotEmpty) {
      _lastPaymentResponse = paymentStatusResponses.removeAt(0);
    }
    final response = _lastPaymentResponse;
    if (response is Error) throw response;
    if (response is Exception) throw response;
    if (response is DeliveryPaymentSession) return response;
    throw StateError('No payment status response configured.');
  }

  @override
  Future<DeliveryPaymentSession> createPaymentSession(
    String riderOrderId,
  ) async {
    createPaymentSessionCalls++;
    if (createCompleter != null) return createCompleter!.future;
    final session = createdSession;
    if (session == null) {
      throw StateError('No created payment session configured.');
    }
    return session;
  }

  @override
  Future<DeliveryCompletionModel> completeDelivery(
    String riderOrderId,
  ) async {
    completeDeliveryCalls++;
    return completion;
  }

  @override
  Future<RiderOrderModel> getOne(String riderOrderId) async {
    if (_lastCurrent.isNotEmpty) return _lastCurrent.first;
    throw UnsupportedError('getOne');
  }

  @override
  Future<OrderHistoryPageModel> getHistory({
    required OrderHistoryFilter filter,
    required int page,
    required int pageSize,
  }) async {
    return OrderHistoryPageModel(
      items: _lastCurrent,
      total: _lastCurrent.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<void> markArrived(String riderOrderId) async {}

  @override
  Future<void> scanPickupQr(String riderOrderId, String token) async {}

  @override
  Future<void> pickupSuccess(String riderOrderId) async {}

  @override
  Future<void> startDelivery(String riderOrderId) async {}

  @override
  Future<void> collectCash(String riderOrderId) async {}

  @override
  Future<void> cancel(String riderOrderId, String reason) async {}
}
