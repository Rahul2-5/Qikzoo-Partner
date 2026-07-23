import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:delivery_partner_app/core/api/api_client.dart';
import 'package:delivery_partner_app/core/api/api_endpoints.dart';
import 'package:delivery_partner_app/models/dashboard/dashboard_stats_model.dart';
import 'package:delivery_partner_app/repositories/dashboard/dashboard_repository.dart';
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

DioDashboardRepository buildRepository(FakeHttpClientAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return DioDashboardRepository(apiClient: ApiClient(dio));
}

/// Routes each of the 3 parallel GETs `getStats()` fires to its own
/// canned response, keyed by path — profile/earnings/wallet each need an
/// independently shaped payload.
FakeHttpClientAdapter routedAdapter({
  String profileJson = '{"data":{"name":"Ravi Kumar","availabilityStatus":"ONLINE","rating":4.7,"totalOffers":50,"totalAccepted":46,"totalOrdersCancelled":2,"city":"Bengaluru","state":"Karnataka"}}',
  String earningsJson = '{"data":{"today":{"deliveries":14,"earningsPaise":84200,"tipsPaise":500},"thisWeek":{},"lifetime":{}}}',
  String walletJson = '{"data":{"availableBalancePaise":312000,"lifetimeEarningsPaise":900000,"lifetimePayoutsPaise":600000}}',
  String? onlineJson,
  String? offlineJson,
}) {
  return FakeHttpClientAdapter((options) {
    if (options.path == ApiEndpoints.riderProfile) {
      return jsonResponse(profileJson, 200);
    }
    if (options.path == ApiEndpoints.riderEarningsSummary) {
      return jsonResponse(earningsJson, 200);
    }
    if (options.path == ApiEndpoints.riderWallet) {
      return jsonResponse(walletJson, 200);
    }
    if (options.path == ApiEndpoints.riderAvailabilityOnline) {
      return jsonResponse(onlineJson ?? '{}', 204);
    }
    if (options.path == ApiEndpoints.riderAvailabilityOffline) {
      return jsonResponse(offlineJson ?? '{}', 204);
    }
    throw StateError('Unexpected request to ${options.path}');
  });
}

void main() {
  group('DioDashboardRepository.getStats', () {
    test('parses profile + earnings + wallet into a single snapshot', () async {
      final repo = buildRepository(routedAdapter());

      final stats = await repo.getStats();

      expect(stats.riderName, 'Ravi Kumar');
      expect(stats.availabilityStatus, RiderAvailabilityStatus.online);
      expect(stats.todaysEarningsPaise, 84200);
      expect(stats.todaysDeliveries, 14);
      expect(stats.walletBalancePaise, 312000);
      expect(stats.acceptanceRatePercent, closeTo(92, 0.01));
      expect(stats.completionRatePercent, closeTo(95.65, 0.01));
      expect(stats.rating, 4.7);
      expect(stats.workingZone, 'Bengaluru, Karnataka');
    });

    test('acceptance rate is null when the rider has never been offered a job', () async {
      final repo = buildRepository(routedAdapter(
        profileJson:
            '{"data":{"name":"New Rider","availabilityStatus":"OFFLINE","rating":5,"totalOffers":0,"totalAccepted":0,"totalOrdersCancelled":0,"city":null,"state":null}}',
      ));

      final stats = await repo.getStats();

      expect(stats.acceptanceRatePercent, isNull);
      expect(stats.completionRatePercent, isNull);
      expect(stats.workingZone, isNull);
    });

    test('parses every RiderAvailabilityStatus value the backend can send', () async {
      for (final entry in {
        'OFFLINE': RiderAvailabilityStatus.offline,
        'ONLINE': RiderAvailabilityStatus.online,
        'AVAILABLE': RiderAvailabilityStatus.available,
        'BUSY': RiderAvailabilityStatus.busy,
        'BREAK': RiderAvailabilityStatus.onBreak,
        'LOGGED_OUT': RiderAvailabilityStatus.loggedOut,
      }.entries) {
        final repo = buildRepository(routedAdapter(
          profileJson:
              '{"data":{"name":"Ravi","availabilityStatus":"${entry.key}","rating":5,"totalOffers":1,"totalAccepted":1,"totalOrdersCancelled":0}}',
        ));
        final stats = await repo.getStats();
        expect(stats.availabilityStatus, entry.value, reason: entry.key);
      }
    });

    test('handles an unwrapped (non-envelope) response body', () async {
      final repo = buildRepository(routedAdapter(
        profileJson:
            '{"name":"Ravi Kumar","availabilityStatus":"OFFLINE","rating":5,"totalOffers":0,"totalAccepted":0,"totalOrdersCancelled":0}',
      ));
      final stats = await repo.getStats();
      expect(stats.riderName, 'Ravi Kumar');
    });
  });

  group('DioDashboardRepository.goOnline / goOffline', () {
    test('goOnline posts to the online endpoint then refreshes the full snapshot', () async {
      final adapter = routedAdapter();
      final repo = buildRepository(adapter);

      final stats = await repo.goOnline();

      expect(adapter.requestedPaths, contains(ApiEndpoints.riderAvailabilityOnline));
      expect(stats.todaysDeliveries, 14);
    });

    test('goOffline posts to the offline endpoint then refreshes the full snapshot', () async {
      final adapter = routedAdapter();
      final repo = buildRepository(adapter);

      final stats = await repo.goOffline();

      expect(adapter.requestedPaths, contains(ApiEndpoints.riderAvailabilityOffline));
      expect(stats.walletBalancePaise, 312000);
    });
  });
}
