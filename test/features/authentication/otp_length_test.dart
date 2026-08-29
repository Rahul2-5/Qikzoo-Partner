import 'package:delivery_partner_app/core/constants/app_constants.dart';
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
}
