import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/orders/rider_order_model.dart';

Map<String, dynamic> baseRiderOrderJson({
  String status = 'ACCEPTED',
  String? customerPhone = '9999999999',
  Map<String, dynamic>? pickupQr,
  Map<String, dynamic>? deliveryOtp,
  List<Map<String, dynamic>>? statusHistory,
}) {
  return {
    'id': 'rider-order-1',
    'orderId': 'order-1',
    'status': status,
    'distanceKm': 3.4,
    'earningsPaise': 4200,
    'tipsPaise': 500,
    'etaMinutes': 12.5,
    'assignedAt': '2026-07-23T10:00:00.000Z',
    'acceptedAt': '2026-07-23T10:00:05.000Z',
    'arrivedAt': null,
    'pickedUpAt': null,
    'outForDeliveryAt': null,
    'deliveredAt': null,
    'cancelledAt': null,
    'cancellationReason': null,
    'restaurant': {
      'name': 'Spice Route Kitchen',
      'phone': '9000000001',
      'address': '1 MG Road',
      'landmark': 'Near Metro',
      'latitude': 12.97,
      'longitude': 77.59,
    },
    'order': {
      'id': 'order-1',
      'orderNumber': 'BR-1',
      'customerName': 'Asha Rao',
      'customerPhone': customerPhone,
      'deliveryAddressLine': '221B Baker Street',
      'deliveryCity': 'Bengaluru',
      'deliveryPincode': '560001',
      'deliveryLat': 12.99,
      'deliveryLng': 77.61,
      'totalPaise': 45000,
      'customerNote': 'Ring the bell',
      'status': 'HANDED_TO_RIDER',
      if (statusHistory != null) 'statusHistory': statusHistory,
    },
    'pickupQr': pickupQr,
    'deliveryOtp': deliveryOtp,
  };
}

void main() {
  group('RiderOrderStatus.fromBackend', () {
    test('maps every backend value', () {
      expect(RiderOrderStatus.fromBackend('ASSIGNED'), RiderOrderStatus.assigned);
      expect(RiderOrderStatus.fromBackend('ACCEPTED'), RiderOrderStatus.accepted);
      expect(RiderOrderStatus.fromBackend('ARRIVED_AT_RESTAURANT'),
          RiderOrderStatus.arrivedAtRestaurant);
      expect(RiderOrderStatus.fromBackend('PICKED_UP'), RiderOrderStatus.pickedUp);
      expect(RiderOrderStatus.fromBackend('OUT_FOR_DELIVERY'),
          RiderOrderStatus.outForDelivery);
      expect(RiderOrderStatus.fromBackend('DELIVERED'), RiderOrderStatus.delivered);
      expect(RiderOrderStatus.fromBackend('CANCELLED'), RiderOrderStatus.cancelled);
      expect(RiderOrderStatus.fromBackend('SOMETHING_NEW'), RiderOrderStatus.unknown);
    });

    test('canCancel mirrors the backend transition guard — only terminal states block it', () {
      expect(RiderOrderStatus.assigned.canCancel, isTrue);
      expect(RiderOrderStatus.accepted.canCancel, isTrue);
      expect(RiderOrderStatus.arrivedAtRestaurant.canCancel, isTrue);
      expect(RiderOrderStatus.pickedUp.canCancel, isTrue);
      expect(RiderOrderStatus.outForDelivery.canCancel, isTrue);
      expect(RiderOrderStatus.delivered.canCancel, isFalse);
      expect(RiderOrderStatus.cancelled.canCancel, isFalse);
    });
  });

  group('RiderOrderModel.fromJson', () {
    test('parses restaurant contact and order fields', () {
      final order = RiderOrderModel.fromJson(baseRiderOrderJson());
      expect(order.id, 'rider-order-1');
      expect(order.status, RiderOrderStatus.accepted);
      expect(order.restaurant.name, 'Spice Route Kitchen');
      expect(order.restaurant.phone, '9000000001');
      expect(order.restaurant.landmark, 'Near Metro');
      expect(order.order.orderNumber, 'BR-1');
      expect(order.order.deliveryCity, 'Bengaluru');
      expect(order.earningsPaise, 4200);
      expect(order.tipsPaise, 500);
    });

    test('customer phone is exposed when the backend returns a non-null value', () {
      final order =
          RiderOrderModel.fromJson(baseRiderOrderJson(customerPhone: '9998887777'));
      expect(order.order.customerPhone, '9998887777');
    });

    test('customer phone stays null when the backend redacts it (not yet arrived)', () {
      final order = RiderOrderModel.fromJson(baseRiderOrderJson(customerPhone: null));
      expect(order.order.customerPhone, isNull);
    });

    test('statusHistory is null on list responses and populated on the detail response', () {
      final withoutHistory = RiderOrderModel.fromJson(baseRiderOrderJson());
      expect(withoutHistory.order.statusHistory, isNull);

      final withHistory = RiderOrderModel.fromJson(baseRiderOrderJson(statusHistory: [
        {
          'fromStatus': 'NEW',
          'toStatus': 'ACCEPTED',
          'reason': null,
          'changedAt': '2026-07-23T09:00:00.000Z',
        },
        {
          'fromStatus': 'ACCEPTED',
          'toStatus': 'HANDED_TO_RIDER',
          'reason': null,
          'changedAt': '2026-07-23T09:30:00.000Z',
        },
      ]));
      expect(withHistory.order.statusHistory, hasLength(2));
      expect(withHistory.order.statusHistory!.last.toStatus,
          RestaurantOrderStatus.handedToRider);
    });

    test('parses pickupQr and deliveryOtp when present, null when absent', () {
      final withoutCheckpoints = RiderOrderModel.fromJson(baseRiderOrderJson());
      expect(withoutCheckpoints.pickupQr, isNull);
      expect(withoutCheckpoints.deliveryOtp, isNull);

      final withCheckpoints = RiderOrderModel.fromJson(baseRiderOrderJson(
        pickupQr: {'status': 'USED', 'expiresAt': '2026-07-23T12:00:00.000Z'},
        deliveryOtp: {
          'status': 'ACTIVE',
          'attempts': 2,
          'maxAttempts': 5,
          'expiresAt': '2026-07-23T12:45:00.000Z',
        },
      ));
      expect(withCheckpoints.pickupQr!.status, PickupQrStatus.used);
      expect(withCheckpoints.deliveryOtp!.attempts, 2);
      expect(withCheckpoints.deliveryOtp!.attemptsRemaining, 3);
    });

    test('handles an unwrapped (non-envelope) response body', () {
      final json = baseRiderOrderJson();
      final order = RiderOrderModel.fromJson(json);
      expect(order.id, 'rider-order-1');
    });
  });
}
