import 'package:delivery_partner_app/core/constants/app_constants.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/shared/widgets/inputs/otp_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OTP field defaults to exactly four digits', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpField(onCompleted: (_) {}),
        ),
      ),
    );

    final field = tester.widget<OtpField>(find.byType(OtpField));
    expect(AppConstants.otpLength, 4);
    expect(field.length, 4);
  });

  test('authentication rejects OTPs that are not exactly four digits',
      () async {
    final repository = MockAuthRepository();

    await expectLater(
      repository.verifyOtp('9876543210', '123'),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      repository.verifyOtp('9876543210', '12345'),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      repository.verifyOtp('9876543210', '12a4'),
      throwsA(isA<FormatException>()),
    );
  });
}
