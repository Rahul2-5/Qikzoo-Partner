import 'package:delivery_partner_app/models/orders/delivery_payment_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unknown backend payment status maps safely without crashing', () {
    final session = DeliveryPaymentSession.fromJson(
      {
        'sessionId': 'session-1',
        'amountPaise': 34900,
        'status': 'SOMETHING_NEW',
        'qrPayload': 'backend-payload',
        'expiresAt': '2026-08-22T18:30:00.000Z',
      },
      riderOrderId: 'rider-order-1',
    );

    expect(session.status, DeliveryPaymentStatus.connectionError);
    expect(session.backendStatus, 'SOMETHING_NEW');
  });

  test('order PAID status safely wins over a lagging session status', () {
    final session = DeliveryPaymentSession.fromJson(
      {
        'sessionId': 'session-1',
        'amountPaise': 34900,
        'status': 'PENDING',
        'orderPaymentStatus': 'PAID',
        'qrPayload': 'backend-payload',
        'expiresAt': '2026-08-22T18:30:00.000Z',
      },
      riderOrderId: 'rider-order-1',
    );

    expect(session.status, DeliveryPaymentStatus.success);
  });

  test('raw gateway exception payload is not exposed as a failure reason', () {
    final session = DeliveryPaymentSession.fromJson(
      {
        'sessionId': 'session-1',
        'amountPaise': 34900,
        'status': 'FAILED',
        'qrPayload': 'backend-payload',
        'expiresAt': '2026-08-22T18:30:00.000Z',
        'failureReason': 'GatewayException { stack: secret payload }',
      },
      riderOrderId: 'rider-order-1',
    );

    expect(session.status, DeliveryPaymentStatus.failed);
    expect(
      session.failureReason,
      'The payment could not be completed. Please try again.',
    );
  });

  test('legacy provider QR failure code becomes neutral copy', () {
    final session = DeliveryPaymentSession.fromJson(
      {
        'sessionId': 'session-1',
        'amountPaise': 25600,
        'status': 'FAILED',
        'qrPayload': '',
        'expiresAt': '2026-08-22T18:30:00.000Z',
        'failureReason': 'PAYU_QR_GENERATION_FAILED',
      },
      riderOrderId: 'rider-order-1',
    );

    expect(
      session.failureReason,
      'Payment QR could not be generated. Please try again.',
    );
  });
}
