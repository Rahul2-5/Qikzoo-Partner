import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

class DioService {
  DioService(this._storage) : dio = Dio(_baseOptions) {
    dio.interceptors.add(_authInterceptor());
  }

  final SecureTokenStorage _storage;
  final Dio dio;

  static final BaseOptions _baseOptions = BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
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

        final refreshed = await _refreshAccessToken();
        if (refreshed == null) {
          await _storage.clearTokens();
          handler.next(error);
          return;
        }

        final retryOptions = error.requestOptions;
        retryOptions.extra['retried'] = true;
        retryOptions.headers['Authorization'] = 'Bearer $refreshed';

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

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final refreshDio = Dio(_baseOptions);
      final response = await refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.riderRefresh,
        data: {'refreshToken': refreshToken},
      );
      final data = response.data;
      if (data == null) return null;

      final accessToken = data['accessToken'] ?? data['token'];
      final newRefreshToken = data['refreshToken'];
      if (accessToken is! String || accessToken.isEmpty) return null;

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken is String ? newRefreshToken : null,
      );
      return accessToken;
    } on DioException {
      return null;
    }
  }
}
