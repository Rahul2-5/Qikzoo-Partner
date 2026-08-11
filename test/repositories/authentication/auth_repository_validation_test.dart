import 'package:delivery_partner_app/core/api/api_client.dart';
import 'package:delivery_partner_app/core/storage/secure_storage.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requestOtp rejects a repeated-digit number before making a request',
      () async {
    // The Dio instance is never touched — validation must throw
    // synchronously before any request is attempted.
    final repository = DioAuthRepository(
      apiClient: ApiClient(Dio()),
      storage: SecureTokenStorage(),
    );

    await expectLater(
      repository.requestOtp('9999999999'),
      throwsA(isA<FormatException>()),
    );
  });
}
