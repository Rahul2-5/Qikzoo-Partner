import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.data,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Object? data;

  factory ApiException.fromDioException(DioException error) {
    final response = error.response;
    final data = response?.data;

    return ApiException(
      message: _messageFor(error, data),
      statusCode: response?.statusCode,
      code: error.type.name,
      data: data,
    );
  }

  static String _messageFor(DioException error, Object? data) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return 'Verification failed due to a server issue. Please try again later.';
    }

    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) return message;

      final error = data['error'];
      if (error is Map<String, dynamic>) {
        final details = error['details'];
        if (details is List && details.isNotEmpty) {
          final firstDetail = details.first;
          if (firstDetail is String && firstDetail.trim().isNotEmpty) {
            return firstDetail;
          }
        }

        final nestedMessage = error['message'];
        if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
          return nestedMessage;
        }
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.badResponse:
        return 'Request failed. Please try again.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Unable to connect. Check your internet connection.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed.';
      case DioExceptionType.unknown:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() =>
      'ApiException(message: $message, statusCode: $statusCode, code: $code)';
}
