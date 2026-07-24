import 'package:dio/dio.dart';

import 'api_exception.dart';

class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _send(
        () => _dio.get<T>(
          path,
          queryParameters: queryParameters,
          options: options,
        ),
      );

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      _send(
        () => _dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          onSendProgress: onSendProgress,
          cancelToken: cancelToken,
        ),
      );

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _send(
        () => _dio.put<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ),
      );

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _send(
        () => _dio.patch<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ),
      );

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _send(
        () => _dio.delete<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ),
      );

  Future<Response<T>> _send<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
