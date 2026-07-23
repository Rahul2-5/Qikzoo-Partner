import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:delivery_partner_app/core/api/api_client.dart';
import 'package:delivery_partner_app/core/api/api_endpoints.dart';
import 'package:delivery_partner_app/models/orders/dispatch_offer_model.dart';
import 'package:delivery_partner_app/repositories/orders/dispatch_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;
  final List<String> requestedPaths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPaths.add(options.path);
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

DioDispatchRepository buildRepository(FakeHttpClientAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return DioDispatchRepository(apiClient: ApiClient(dio));
}

void main() {
  group('DioDispatchRepository.getCurrentOffer', () {
    test('parses a present offer from the envelope', () async {
      final adapter = FakeHttpClientAdapter((options) {
        expect(options.path, ApiEndpoints.riderDispatchCurrent);
        return jsonResponse(
          '{"data":{"id":"attempt-1","jobId":"job-1","attemptNumber":1,'
          '"status":"WAITING_RIDER","distanceKm":2.5,"broadcast":false,'
          '"offeredAt":"2026-07-23T10:00:00.000Z","expiresAt":"2026-07-23T10:00:20.000Z"}}',
          200,
        );
      });
      final repo = buildRepository(adapter);

      final offer = await repo.getCurrentOffer();

      expect(offer, isA<DispatchOfferModel>());
      expect(offer!.id, 'attempt-1');
      expect(offer.distanceKm, 2.5);
    });

    test('returns null when the backend has no outstanding offer', () async {
      final adapter = FakeHttpClientAdapter((options) => jsonResponse('{"data":null}', 200));
      final repo = buildRepository(adapter);

      final offer = await repo.getCurrentOffer();

      expect(offer, isNull);
    });
  });

  group('DioDispatchRepository.accept / reject', () {
    test('accept posts to the attempt-scoped accept endpoint', () async {
      final adapter = FakeHttpClientAdapter((options) {
        expect(options.path, ApiEndpoints.riderDispatchAccept('attempt-1'));
        expect(options.method, 'POST');
        return jsonResponse('{"data":{}}', 201);
      });
      final repo = buildRepository(adapter);

      await repo.accept('attempt-1');

      expect(adapter.requestedPaths, contains('/rider/dispatch/attempt-1/accept'));
    });

    test('reject posts to the attempt-scoped reject endpoint', () async {
      final adapter = FakeHttpClientAdapter((options) {
        expect(options.path, ApiEndpoints.riderDispatchReject('attempt-1'));
        return jsonResponse('{"data":{"success":true}}', 201);
      });
      final repo = buildRepository(adapter);

      await repo.reject('attempt-1');

      expect(adapter.requestedPaths, contains('/rider/dispatch/attempt-1/reject'));
    });
  });
}
