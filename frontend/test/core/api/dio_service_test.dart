import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:delivery_partner_app/core/api/dio_service.dart';
import 'package:delivery_partner_app/core/storage/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal fake transport so these tests exercise DioService's real
/// interceptor/refresh logic without touching the network. Responses are
/// produced by [handler] per request, keyed on whatever the test cares
/// about (path, call count, ...).
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Fresh in-memory secure storage per test (the official test seam —
    // see flutter_secure_storage's setMockInitialValues).
    FlutterSecureStorage.setMockInitialValues({});
    // AppConfig.apiBaseUrl reads dotenv; DioService's base options are
    // never actually used by these tests (the adapter is always swapped
    // out), but constructing it requires dotenv to be initialized.
    dotenv.testLoad();
  });

  group('refreshSession', () {
    test('returns invalidToken and does not call the network when no refresh token is stored',
        () async {
      final storage = SecureTokenStorage();
      final service = DioService(storage);
      var callCount = 0;
      service.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
        callCount++;
        return jsonResponse('{}', 200);
      });

      final result = await service.refreshSession();

      expect(result, SessionRefreshResult.invalidToken);
      expect(callCount, 0);
    });

    test('unwraps the { data: {...} } envelope and saves the new tokens on success', () async {
      final storage = SecureTokenStorage();
      await storage.saveTokens(accessToken: 'old-access', refreshToken: 'old-refresh');
      final service = DioService(storage);
      service.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
        return jsonResponse(
          '{"data":{"accessToken":"new-access","refreshToken":"new-refresh","expiresIn":"15m","sessionId":"s1"}}',
          200,
        );
      });

      final result = await service.refreshSession();

      expect(result, SessionRefreshResult.success);
      expect(await storage.getAccessToken(), 'new-access');
      expect(await storage.getRefreshToken(), 'new-refresh');
    });

    test('clears tokens and returns invalidToken on a 401 (expired/invalid refresh token)',
        () async {
      final storage = SecureTokenStorage();
      await storage.saveTokens(accessToken: 'old-access', refreshToken: 'old-refresh');
      final service = DioService(storage);
      service.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
        return jsonResponse('{"error":{"message":"Invalid or expired refresh token"}}', 401);
      });

      final result = await service.refreshSession();

      expect(result, SessionRefreshResult.invalidToken);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('returns networkError and preserves tokens when the server is unreachable', () async {
      final storage = SecureTokenStorage();
      await storage.saveTokens(accessToken: 'old-access', refreshToken: 'old-refresh');
      final service = DioService(storage);
      service.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
        throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
      });

      final result = await service.refreshSession();

      expect(result, SessionRefreshResult.networkError);
      expect(await storage.getAccessToken(), 'old-access');
      expect(await storage.getRefreshToken(), 'old-refresh');
    });

    test('returns networkError and preserves tokens on a 5xx server error', () async {
      final storage = SecureTokenStorage();
      await storage.saveTokens(accessToken: 'old-access', refreshToken: 'old-refresh');
      final service = DioService(storage);
      service.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
        return jsonResponse('{"error":{"message":"down for maintenance"}}', 503);
      });

      final result = await service.refreshSession();

      expect(result, SessionRefreshResult.networkError);
      expect(await storage.getAccessToken(), 'old-access');
      expect(await storage.getRefreshToken(), 'old-refresh');
    });
  });

  group('auth interceptor', () {
    test('attaches the stored access token to a protected request', () async {
      final storage = SecureTokenStorage();
      await storage.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1');
      final service = DioService(storage);
      service.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
        expect(options.headers['Authorization'], 'Bearer access-1');
        return jsonResponse('{"data":{"ok":true}}', 200);
      });

      await service.dio.get<Map<String, dynamic>>('/rider/profile');
    });

    test('does not attach a token to auth endpoints', () async {
      final storage = SecureTokenStorage();
      await storage.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1');
      final service = DioService(storage);
      service.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
        expect(options.headers.containsKey('Authorization'), isFalse);
        return jsonResponse('{"data":{"ok":true}}', 200);
      });

      await service.dio.post<Map<String, dynamic>>('/rider/auth/request-otp');
    });

    test('a 401 triggers exactly one silent refresh-and-retry, then succeeds', () async {
      final storage = SecureTokenStorage();
      await storage.saveTokens(accessToken: 'expired-access', refreshToken: 'refresh-1');
      final service = DioService(storage);

      var profileCalls = 0;
      service.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
        if (options.path == '/rider/auth/refresh') {
          return jsonResponse(
            '{"data":{"accessToken":"fresh-access","refreshToken":"refresh-2"}}',
            200,
          );
        }
        profileCalls++;
        if (options.headers['Authorization'] == 'Bearer expired-access') {
          return jsonResponse('{"error":{"message":"expired"}}', 401);
        }
        expect(options.headers['Authorization'], 'Bearer fresh-access');
        return jsonResponse('{"data":{"id":"rider_1"}}', 200);
      });

      final response =
          await service.dio.get<Map<String, dynamic>>('/rider/profile');

      expect(response.statusCode, 200);
      expect(profileCalls, 2);
      expect(await storage.getAccessToken(), 'fresh-access');
    });

    test('does not loop when the retried request also fails', () async {
      final storage = SecureTokenStorage();
      await storage.saveTokens(accessToken: 'expired-access', refreshToken: 'refresh-1');
      final service = DioService(storage);

      var profileCalls = 0;
      service.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
        if (options.path == '/rider/auth/refresh') {
          return jsonResponse('{"data":{"accessToken":"fresh-access"}}', 200);
        }
        profileCalls++;
        return jsonResponse('{"error":{"message":"still unauthorized"}}', 401);
      });

      await expectLater(
        service.dio.get<Map<String, dynamic>>('/rider/profile'),
        throwsA(isA<DioException>()),
      );
      // Exactly one retry: the original call plus one retried call, never more.
      expect(profileCalls, 2);
    });

    test(
        'two concurrent 401s share one refresh call and both requests succeed '
        '(no rotated-token race that would wipe the just-refreshed session)',
        () async {
      final storage = SecureTokenStorage();
      await storage.saveTokens(accessToken: 'expired-access', refreshToken: 'refresh-1');
      final service = DioService(storage);

      var refreshCalls = 0;
      final refreshCompleter = Completer<void>();
      service.dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        if (options.path == '/rider/auth/refresh') {
          refreshCalls++;
          // Hold the response open just long enough for both 401s to have
          // already called refreshSession() before either completes —
          // reproducing the concurrency window that causes the race.
          await refreshCompleter.future;
          return jsonResponse(
            '{"data":{"accessToken":"fresh-access","refreshToken":"refresh-2"}}',
            200,
          );
        }
        if (options.headers['Authorization'] == 'Bearer expired-access') {
          return jsonResponse('{"error":{"message":"expired"}}', 401);
        }
        expect(options.headers['Authorization'], 'Bearer fresh-access');
        return jsonResponse('{"data":{"ok":true}}', 200);
      });

      final first = service.dio.get<Map<String, dynamic>>('/rider/profile');
      final second = service.dio.get<Map<String, dynamic>>('/rider/orders');
      // Let both requests reach their 401 and call refreshSession() before
      // the fake refresh response is allowed to resolve.
      await Future<void>.delayed(Duration.zero);
      refreshCompleter.complete();

      final responses = await Future.wait([first, second]);

      expect(responses[0].statusCode, 200);
      expect(responses[1].statusCode, 200);
      expect(refreshCalls, 1);
      expect(await storage.getAccessToken(), 'fresh-access');
      expect(await storage.getRefreshToken(), 'refresh-2');
    });

    test('a 401 with an invalid refresh token clears storage and does not retry', () async {
      final storage = SecureTokenStorage();
      await storage.saveTokens(accessToken: 'expired-access', refreshToken: 'bad-refresh');
      final service = DioService(storage);

      var profileCalls = 0;
      service.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
        if (options.path == '/rider/auth/refresh') {
          return jsonResponse('{"error":{"message":"invalid refresh token"}}', 401);
        }
        profileCalls++;
        return jsonResponse('{"error":{"message":"unauthorized"}}', 401);
      });

      await expectLater(
        service.dio.get<Map<String, dynamic>>('/rider/profile'),
        throwsA(isA<DioException>()),
      );
      expect(profileCalls, 1);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });
  });
}
