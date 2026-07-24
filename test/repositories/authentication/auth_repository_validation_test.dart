import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requestOtp rejects a repeated-digit number before making a request',
      () async {
    await expectLater(
      MockAuthRepository().requestOtp('9999999999'),
      throwsA(isA<FormatException>()),
    );
  });
}
