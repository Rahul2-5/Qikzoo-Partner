import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/orders/dispatch_offer_model.dart';

void main() {
  group('DispatchAttemptStatus.fromBackend', () {
    test('maps every backend value', () {
      expect(DispatchAttemptStatus.fromBackend('WAITING_RIDER'),
          DispatchAttemptStatus.waitingRider);
      expect(DispatchAttemptStatus.fromBackend('ACCEPTED'), DispatchAttemptStatus.accepted);
      expect(DispatchAttemptStatus.fromBackend('REJECTED'), DispatchAttemptStatus.rejected);
      expect(DispatchAttemptStatus.fromBackend('EXPIRED'), DispatchAttemptStatus.expired);
      expect(DispatchAttemptStatus.fromBackend('CANCELLED'), DispatchAttemptStatus.cancelled);
      expect(DispatchAttemptStatus.fromBackend('X'), DispatchAttemptStatus.unknown);
    });
  });

  group('DispatchOfferModel.fromJson', () {
    test('parses the bare DispatchAttempt fields the backend actually returns', () {
      final offer = DispatchOfferModel.fromJson({
        'id': 'attempt-1',
        'jobId': 'job-1',
        'attemptNumber': 1,
        'status': 'WAITING_RIDER',
        'distanceKm': 2.4,
        'searchRadiusKm': 5.0,
        'broadcast': false,
        'offeredAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(const Duration(seconds: 20)).toIso8601String(),
      });

      expect(offer.id, 'attempt-1');
      expect(offer.distanceKm, 2.4);
      expect(offer.broadcast, isFalse);
      expect(offer.status, DispatchAttemptStatus.waitingRider);
    });

    test('remaining counts down to zero and never goes negative', () {
      final offer = DispatchOfferModel.fromJson({
        'id': 'attempt-1',
        'jobId': 'job-1',
        'attemptNumber': 1,
        'status': 'WAITING_RIDER',
        'distanceKm': 2.4,
        'broadcast': false,
        'offeredAt': DateTime.now().subtract(const Duration(seconds: 30)).toIso8601String(),
        'expiresAt': DateTime.now().subtract(const Duration(seconds: 10)).toIso8601String(),
      });

      expect(offer.remaining, Duration.zero);
      expect(offer.isExpired, isTrue);
    });

    test('broadcast attempts are flagged', () {
      final offer = DispatchOfferModel.fromJson({
        'id': 'attempt-1',
        'jobId': 'job-1',
        'attemptNumber': 3,
        'status': 'WAITING_RIDER',
        'distanceKm': 4.0,
        'broadcast': true,
        'offeredAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(const Duration(seconds: 20)).toIso8601String(),
      });

      expect(offer.broadcast, isTrue);
    });
  });
}
