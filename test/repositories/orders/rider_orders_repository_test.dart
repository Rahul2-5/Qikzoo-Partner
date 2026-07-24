import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:delivery_partner_app/core/api/api_client.dart';
import 'package:delivery_partner_app/core/api/api_endpoints.dart';
import 'package:delivery_partner_app/models/orders/order_history_page_model.dart';
import 'package:delivery_partner_app/repositories/orders/rider_orders_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(String body, int statusCode) => ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );

DioRiderOrdersRepository buildRepository(FakeHttpClientAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return DioRiderOrdersRepository(apiClient: ApiClient(dio));
}

const _riderOrderJson = '{"id":"rider-order-1","orderId":"order-1","status":"ACCEPTED",'
    '"distanceKm":3.0,"earningsPaise":0,"tipsPaise":0,"assignedAt":"2026-07-23T10:00:00.000Z",'
    '"restaurant":{"name":"Test Kitchen","phone":"9000000001","address":"1 MG Road",'
    '"landmark":null,"latitude":12.9,"longitude":77.6},'
    '"order":{"id":"order-1","orderNumber":"BR-1","customerName":"Asha",'
    '"customerPhone":null,"status":"ACCEPTED"}}';

void main() {
  group('DioRiderOrdersRepository.getCurrent', () {
    test('parses the current-orders list', () async {
      final adapter = FakeHttpClientAdapter(
          (options) => jsonResponse('{"data":[$_riderOrderJson]}', 200));
      final repo = buildRepository(adapter);

      final current = await repo.getCurrent();

      expect(current, hasLength(1));
      expect(current.first.id, 'rider-order-1');
      expect(requestsPathOf(adapter), ApiEndpoints.riderOrdersCurrent);
    });

    test('returns an empty list when there is no active order', () async {
      final adapter = FakeHttpClientAdapter((options) => jsonResponse('{"data":[]}', 200));
      final repo = buildRepository(adapter);

      expect(await repo.getCurrent(), isEmpty);
    });
  });

  group('DioRiderOrdersRepository.getOne', () {
    test('requests the order-scoped detail endpoint', () async {
      final adapter = FakeHttpClientAdapter((options) {
        expect(options.path, ApiEndpoints.riderOrderDetail('rider-order-1'));
        return jsonResponse('{"data":$_riderOrderJson}', 200);
      });
      final repo = buildRepository(adapter);

      final order = await repo.getOne('rider-order-1');

      expect(order.id, 'rider-order-1');
    });
  });

  group('DioRiderOrdersRepository.getHistory', () {
    test('sends the status/page/pageSize query parameters', () async {
      final adapter = FakeHttpClientAdapter((options) {
        expect(options.path, ApiEndpoints.riderOrdersHistory);
        expect(options.queryParameters['status'], 'COMPLETED');
        expect(options.queryParameters['page'], 2);
        expect(options.queryParameters['pageSize'], 20);
        return jsonResponse(
          '{"data":{"items":[$_riderOrderJson],"total":25,"page":2,"pageSize":20}}',
          200,
        );
      });
      final repo = buildRepository(adapter);

      final page = await repo.getHistory(
        filter: OrderHistoryFilter.completed,
        page: 2,
        pageSize: 20,
      );

      expect(page.items, hasLength(1));
      expect(page.total, 25);
    });
  });

  group('DioRiderOrdersRepository order-action endpoints', () {
    test('markArrived posts to the arrived endpoint', () async {
      final adapter = FakeHttpClientAdapter((options) {
        expect(options.path, ApiEndpoints.riderOrderArrived('rider-order-1'));
        return jsonResponse('{"data":{}}', 201);
      });
      await buildRepository(adapter).markArrived('rider-order-1');
    });

    test('scanPickupQr posts the decoded token', () async {
      final adapter = FakeHttpClientAdapter((options) {
        expect(options.path, ApiEndpoints.riderOrderScanPickupQr('rider-order-1'));
        expect(options.data, {'token': 'the-token'});
        return jsonResponse('{"data":{}}', 201);
      });
      await buildRepository(adapter).scanPickupQr('rider-order-1', 'the-token');
    });

    test('pickupSuccess posts to the pickup-success endpoint', () async {
      final adapter = FakeHttpClientAdapter((options) {
        expect(options.path, ApiEndpoints.riderOrderPickupSuccess('rider-order-1'));
        return jsonResponse('{"data":{}}', 201);
      });
      await buildRepository(adapter).pickupSuccess('rider-order-1');
    });

    test('startDelivery posts to the start-delivery endpoint', () async {
      final adapter = FakeHttpClientAdapter((options) {
        expect(options.path, ApiEndpoints.riderOrderStartDelivery('rider-order-1'));
        return jsonResponse('{"data":{}}', 201);
      });
      await buildRepository(adapter).startDelivery('rider-order-1');
    });

    test('completeDelivery posts the OTP code', () async {
      final adapter = FakeHttpClientAdapter((options) {
        expect(options.path, ApiEndpoints.riderOrderCompleteDelivery('rider-order-1'));
        expect(options.data, {'code': '654321'});
        return jsonResponse('{"data":{}}', 201);
      });
      await buildRepository(adapter).completeDelivery('rider-order-1', '654321');
    });

    test('cancel posts the reason', () async {
      final adapter = FakeHttpClientAdapter((options) {
        expect(options.path, ApiEndpoints.riderOrderCancel('rider-order-1'));
        expect(options.data, {'reason': 'Vehicle breakdown'});
        return jsonResponse('{"data":{}}', 201);
      });
      await buildRepository(adapter).cancel('rider-order-1', 'Vehicle breakdown');
    });
  });
}

String requestsPathOf(FakeHttpClientAdapter adapter) => adapter.requests.last.path;
