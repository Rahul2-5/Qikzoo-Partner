import 'package:delivery_partner_app/models/orders/delivery_payment_session.dart';
import 'package:delivery_partner_app/models/orders/rider_order_model.dart';

RiderOrderModel testOrder({
  String paymentMethod = 'COD',
  String paymentStatus = 'PENDING',
  String riderStatus = 'OUT_FOR_DELIVERY',
  DateTime? paidAt,
  String? paymentReference,
}) {
  return RiderOrderModel.fromJson({
    'id': 'rider-order-1',
    'orderId': 'order-1',
    'status': riderStatus,
    'assignedAt': '2026-08-22T10:00:00.000Z',
    'earningsPaise': 5500,
    'restaurant': {
      'name': 'Qikzoo Kitchen',
      'phone': '9999999999',
      'address': 'MG Road',
      'latitude': 12.9716,
      'longitude': 77.5946,
    },
    'order': {
      'id': 'order-1',
      'orderNumber': 'QZ-10001',
      'customerName': 'Asha',
      'customerPhone': '9999999998',
      'deliveryAddressLine': '12 Park Street',
      'deliveryCity': 'Bengaluru',
      'deliveryPincode': '560001',
      'deliveryLat': 12.9717,
      'deliveryLng': 77.5947,
      'totalPaise': 34900,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      if (paidAt != null) 'paidAt': paidAt.toUtc().toIso8601String(),
      if (paymentReference != null) 'paymentReference': paymentReference,
      'status': 'PICKED_UP',
      'items': [
        {'name': 'Meal', 'quantity': 1, 'pricePaise': 34900},
      ],
    },
  });
}

DeliveryPaymentSession testPaymentSession({
  DeliveryPaymentStatus status = DeliveryPaymentStatus.pending,
  DateTime? expiresAt,
  String? transactionId,
  String? failureReason,
}) {
  return DeliveryPaymentSession(
    sessionId: 'session-1',
    riderOrderId: 'rider-order-1',
    qrData: 'qikzoo://delivery-payment/backend-token',
    qrFormat: DeliveryQrFormat.payload,
    amountPaise: 34900,
    status: status,
    expiresAt: expiresAt ?? DateTime.now().add(const Duration(minutes: 10)),
    paidAt: status == DeliveryPaymentStatus.success ? DateTime.now() : null,
    transactionId: transactionId,
    failureReason: failureReason,
    gateway: 'TEST_GATEWAY',
    backendStatus: status.name.toUpperCase(),
  );
}
