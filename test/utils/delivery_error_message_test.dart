import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/features/orders/utils/delivery_error_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backend rejection is translated into a safe rider message', () {
    const backend = ApiException(
      message:
          'Collect the customer payment before completing this delivery. internalCode=PAY_91',
      statusCode: 400,
    );

    final message = riderMessageForDeliveryAction(backend);

    expect(message, contains('Payment is not confirmed'));
    expect(message, isNot(contains('internalCode')));
    expect(message, isNot(contains('PAY_91')));
  });
}
