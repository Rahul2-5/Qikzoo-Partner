import 'dart:async';

import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/models/orders/delivery_payment_session.dart';
import 'package:delivery_partner_app/models/orders/rider_order_model.dart';
import 'package:delivery_partner_app/providers/orders/active_order_provider.dart';
import 'package:delivery_partner_app/providers/orders/delivery_payment_provider.dart';
import 'package:delivery_partner_app/repositories/orders/rider_orders_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_rider_orders_repository.dart';
import '../helpers/order_test_data.dart';

void main() {
  ProviderContainer containerFor(
    FakeRiderOrdersRepository repository, {
    Duration pollInterval = const Duration(hours: 1),
  }) {
    return ProviderContainer(
      overrides: [
        riderOrdersRepositoryProvider.overrideWithValue(repository),
        deliveryPaymentPollIntervalProvider.overrideWithValue(pollInterval),
      ],
    );
  }

  test('only one payment-session request is created for duplicate opens',
      () async {
    final repository = FakeRiderOrdersRepository()
      ..paymentStatusResponses.add(
        const ApiException(message: 'Not found', statusCode: 404),
      )
      ..createCompleter = Completer<DeliveryPaymentSession>();
    final container = containerFor(repository);
    final provider = deliveryPaymentProvider('rider-order-1');
    final subscription = container.listen(provider, (_, __) {});
    final notifier = container.read(provider.notifier);

    final first = notifier.open();
    final second = notifier.open();
    await Future<void>.delayed(Duration.zero);

    expect(repository.createPaymentSessionCalls, 1);
    repository.createCompleter!.complete(testPaymentSession());
    await Future.wait([first, second]);
    expect(repository.createPaymentSessionCalls, 1);

    subscription.close();
    container.dispose();
  });

  test('pending session polls to success and polling stops', () async {
    final repository = FakeRiderOrdersRepository()
      ..paymentStatusResponses.addAll([
        const ApiException(message: 'Not found', statusCode: 404),
        testPaymentSession(status: DeliveryPaymentStatus.success),
      ])
      ..createdSession = testPaymentSession();
    final container = containerFor(
      repository,
      pollInterval: const Duration(milliseconds: 10),
    );
    final provider = deliveryPaymentProvider('rider-order-1');
    final subscription = container.listen(provider, (_, __) {});

    await container.read(provider.notifier).open();
    expect(container.read(provider).status, DeliveryPaymentStatus.pending);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(container.read(provider).status, DeliveryPaymentStatus.success);
    final callsAtSuccess = repository.getPaymentSessionCalls;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(repository.getPaymentSessionCalls, callsAtSuccess);

    subscription.close();
    container.dispose();
  });

  test('network failure never becomes a false payment failure', () async {
    final repository = FakeRiderOrdersRepository()
      ..paymentStatusResponses.add(
        const ApiException(message: 'No connection'),
      );
    final container = containerFor(repository);
    final provider = deliveryPaymentProvider('rider-order-1');
    final subscription = container.listen(provider, (_, __) {});

    await container.read(provider.notifier).open();

    expect(
      container.read(provider).status,
      DeliveryPaymentStatus.connectionError,
    );
    expect(
      container.read(provider).status,
      isNot(DeliveryPaymentStatus.failed),
    );
    expect(repository.createPaymentSessionCalls, 0);

    subscription.close();
    container.dispose();
  });

  test('resume triggers an immediate status refresh', () async {
    final repository = FakeRiderOrdersRepository()
      ..paymentStatusResponses.addAll([
        testPaymentSession(),
        testPaymentSession(),
      ]);
    final container = containerFor(repository);
    final provider = deliveryPaymentProvider('rider-order-1');
    final subscription = container.listen(provider, (_, __) {});
    final notifier = container.read(provider.notifier);

    await notifier.open();
    notifier.pause();
    final callsBeforeResume = repository.getPaymentSessionCalls;
    notifier.resume();
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(repository.getPaymentSessionCalls, callsBeforeResume + 1);

    subscription.close();
    container.dispose();
  });

  test('expired session supports explicit regeneration', () async {
    final expired = testPaymentSession(
      status: DeliveryPaymentStatus.expired,
      expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
    );
    final repository = FakeRiderOrdersRepository()
      ..paymentStatusResponses.addAll([expired, expired])
      ..createdSession = testPaymentSession();
    final container = containerFor(repository);
    final provider = deliveryPaymentProvider('rider-order-1');
    final subscription = container.listen(provider, (_, __) {});
    final notifier = container.read(provider.notifier);

    await notifier.open();
    expect(container.read(provider).status, DeliveryPaymentStatus.expired);
    await notifier.regenerate();

    expect(repository.createPaymentSessionCalls, 1);
    expect(container.read(provider).status, DeliveryPaymentStatus.pending);

    subscription.close();
    container.dispose();
  });

  test('failed session supports retry after authoritative recheck', () async {
    final failed = testPaymentSession(status: DeliveryPaymentStatus.failed);
    final repository = FakeRiderOrdersRepository()
      ..paymentStatusResponses.addAll([failed, failed])
      ..createdSession = testPaymentSession();
    final container = containerFor(repository);
    final provider = deliveryPaymentProvider('rider-order-1');
    final subscription = container.listen(provider, (_, __) {});
    final notifier = container.read(provider.notifier);

    await notifier.open();
    expect(container.read(provider).status, DeliveryPaymentStatus.failed);
    await notifier.regenerate();

    expect(repository.createPaymentSessionCalls, 1);
    expect(container.read(provider).status, DeliveryPaymentStatus.pending);

    subscription.close();
    container.dispose();
  });

  test('reopening a paid order never creates a QR', () async {
    final repository = FakeRiderOrdersRepository()
      ..paymentStatusResponses.add(
        testPaymentSession(status: DeliveryPaymentStatus.success),
      );
    final container = containerFor(repository);
    final provider = deliveryPaymentProvider('rider-order-1');
    final subscription = container.listen(provider, (_, __) {});

    await container.read(provider.notifier).open();

    expect(container.read(provider).status, DeliveryPaymentStatus.success);
    expect(repository.createPaymentSessionCalls, 0);

    subscription.close();
    container.dispose();
  });

  test('polling and timers stop on provider disposal', () async {
    final repository = FakeRiderOrdersRepository()
      ..paymentStatusResponses.add(testPaymentSession());
    final container = containerFor(
      repository,
      pollInterval: const Duration(milliseconds: 20),
    );
    final provider = deliveryPaymentProvider('rider-order-1');
    final subscription = container.listen(provider, (_, __) {});

    await container.read(provider.notifier).open();
    final callsBeforeDispose = repository.getPaymentSessionCalls;
    subscription.close();
    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(repository.getPaymentSessionCalls, callsBeforeDispose);
  });

  test('completing delivery refreshes and clears active orders', () async {
    final order = testOrder(paymentStatus: 'PAID');
    final repository = FakeRiderOrdersRepository()
      ..currentResponses.addAll([
        [order],
        <RiderOrderModel>[],
      ]);
    final container = containerFor(repository);
    final subscription = container.listen(activeOrderProvider, (_, __) {});

    expect(await container.read(activeOrderProvider.future), order);
    final completion = await container
        .read(activeOrderProvider.notifier)
        .completeDelivery(order.id);

    expect(completion.riderOrderId, order.id);
    expect(repository.completeDeliveryCalls, 1);
    expect(repository.getCurrentCalls, 2);
    expect(container.read(activeOrderProvider).valueOrNull, isNull);

    subscription.close();
    container.dispose();
  });
}
