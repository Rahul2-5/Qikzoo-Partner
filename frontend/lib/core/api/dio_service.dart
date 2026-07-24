import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

/// Outcome of an explicit [DioService.refreshSession] call — distinct from a
/// plain bool so callers (e.g. session restore) can tell "the refresh token
/// is invalid/expired, log the rider out" apart from "the network/server is
/// unavailable, leave the stored session alone and let the rider retry".
enum SessionRefreshResult { success, invalidToken, networkError }

class DioService {
  DioService(this._storage) : dio = Dio(_baseOptions) {
    dio.interceptors.add(_authInterceptor());
  }

  final SecureTokenStorage _storage;
  final Dio dio;

  // Refresh tokens are single-use and rotated server-side (see
  // SessionService.rotateSession) — presenting an already-rotated one burns
  // *every* session for the account, not just the stale request. Several
  // authenticated calls can legitimately go out at once (e.g. a dashboard
  // poll timer firing alongside a manual refresh) and all hit a 401 the
  // moment the access token expires; without this guard each one would call
  // the network independently, and every refresh after the first would
  // present a token the first call already rotated away, revoking the
  // brand-new session it just created and forcing an unexpected logout.
  // This makes every concurrent caller share the one in-flight network call.
  Future<SessionRefreshResult>? _refreshInFlight;

  static final BaseOptions _baseOptions = BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    // The development API is hosted on a service that can take longer to
    // wake up after being idle.  The previous 20/30-second limits made the
    // splash screen label a reachable API as an internet failure before its
    // first response arrived.
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final isAuthEndpoint = _isAuthEndpoint(options.path);

        if (!isAuthEndpoint) {
          final token = await _readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        final shouldRefresh = error.response?.statusCode == 401 &&
            error.requestOptions.path != ApiEndpoints.riderRefresh &&
            error.requestOptions.extra['retried'] != true;

        if (!shouldRefresh) {
          handler.next(error);
          return;
        }

        final result = await refreshSession();
        if (result != SessionRefreshResult.success) {
          handler.next(error);
          return;
        }

        final newToken = await _readAccessToken();
        final retryOptions = error.requestOptions;
        retryOptions.extra['retried'] = true;
        retryOptions.headers['Authorization'] = 'Bearer $newToken';

        try {
          final response = await dio.fetch<dynamic>(retryOptions);
          handler.resolve(response);
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      },
    );
  }

  bool _isAuthEndpoint(String path) {
    return path == ApiEndpoints.riderRequestOtp ||
        path == ApiEndpoints.riderVerifyOtp ||
        path == ApiEndpoints.riderRefresh ||
        path == ApiEndpoints.riderLogout;
  }

  Future<String?> _readAccessToken() async {
    try {
      return await _storage.getAccessToken();
    } catch (_) {
      return null;
    }
  }

  /// Rotates the stored refresh token for a new access/refresh pair.
  ///
  /// Reuses [dio] itself rather than a second client: the refresh endpoint
  /// is already excluded from both the request-time Bearer attachment and
  /// the error-time refresh trigger above, so there is no recursion risk,
  /// and every call goes through the one configured client (base URL,
  /// timeouts, interceptors) instead of a second instance that could drift.
  Future<SessionRefreshResult> refreshSession() {
    return _refreshInFlight ??= _doRefreshSession().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<SessionRefreshResult> _doRefreshSession() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _storage.clearTokens();
      return SessionRefreshResult.invalidToken;
    }

    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.riderRefresh,
        data: {'refreshToken': refreshToken},
      );

      // Every backend response is enveloped as `{ data, meta }` (see
      // ResponseInterceptor on the backend) — unwrap it the same way
      // DioAuthRepository does for verify-otp.
      final body = response.data;
      final nested = body?['data'];
      final payload = nested is Map<String, dynamic> ? nested : body;
      if (payload == null) {
        await _storage.clearTokens();
        return SessionRefreshResult.invalidToken;
      }

      final accessToken = payload['accessToken'] ?? payload['token'];
      final newRefreshToken = payload['refreshToken'];
      if (accessToken is! String || accessToken.isEmpty) {
        await _storage.clearTokens();
        return SessionRefreshResult.invalidToken;
      }

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken is String ? newRefreshToken : null,
      );
      return SessionRefreshResult.success;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      // No response at all (timeout/connection error) or a 5xx means the
      // network/server is the problem, not the token — don't clear the
      // session or treat that as "log the rider out".
      if (statusCode == null || statusCode >= 500) {
        return SessionRefreshResult.networkError;
      }
      await _storage.clearTokens();
      return SessionRefreshResult.invalidToken;
    }
  }
}
