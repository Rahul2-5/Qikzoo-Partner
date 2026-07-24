class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error occurred']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found']);
}
