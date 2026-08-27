import 'package:delivery_partner_app/core/theme/app_theme.dart';
import 'package:delivery_partner_app/features/orders/widgets/collect_payment_bottom_sheet.dart';
import 'package:delivery_partner_app/features/orders/widgets/payment_status_widgets.dart';
import 'package:delivery_partner_app/models/orders/delivery_payment_session.dart';
import 'package:delivery_partner_app/providers/orders/delivery_payment_provider.dart';
import 'package:delivery_partner_app/repositories/orders/rider_orders_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../helpers/fake_rider_orders_repository.dart';
import '../helpers/order_test_data.dart';

Widget themed(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('prepaid order does not show collect payment or QR',
      (tester) async {
    await tester.pumpWidget(
      themed(
        OrderPaymentCard(
          order: testOrder(
            paymentMethod: 'ONLINE',
            paymentStatus: 'PAID',
          ),
          canOpenCollection: true,
          onCollectPayment: () {},
        ),
      ),
    );

    expect(find.text('PAID ONLINE'), findsOneWidget);
    expect(find.textContaining('Collect ₹'), findsNothing);
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('unpaid COD shows collect payment action', (tester) async {
    await tester.pumpWidget(
      themed(
        OrderPaymentCard(
          order: testOrder(),
          canOpenCollection: true,
          onCollectPayment: () {},
        ),
      ),
    );

    expect(find.text('COD · PAYMENT REQUIRED'), findsOneWidget);
    expect(find.text('Confirm cash ₹349'), findsOneWidget);
  });

  testWidgets('mark delivered is disabled while payment is unpaid',
      (tester) async {
    await tester.pumpWidget(
      themed(
        DeliveryBottomActionBar(
          paymentVerified: false,
          proximityReady: true,
          waitingForGps: false,
          isLoading: false,
          onComplete: () {},
        ),
      ),
    );

    expect(find.text('Payment Required'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('mark-delivered-button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('verified payment enables mark delivered', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      themed(
        DeliveryBottomActionBar(
          paymentVerified: true,
          proximityReady: true,
          waitingForGps: false,
          isLoading: false,
          onComplete: () => completed = true,
        ),
      ),
    );

    expect(find.text('Mark as Delivered'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('mark-delivered-button')),
    );
    expect(completed, isTrue);
  });

  testWidgets('pending session displays backend QR', (tester) async {
    final repository = FakeRiderOrdersRepository()
      ..paymentStatusResponses.add(testPaymentSession());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          riderOrdersRepositoryProvider.overrideWithValue(repository),
          deliveryPaymentPollIntervalProvider.overrideWithValue(
            const Duration(hours: 1),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CollectPaymentBottomSheet(
              order: testOrder(),
              onPaymentConfirmed: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Waiting for customer payment'), findsOneWidget);
    expect(repository.createPaymentSessionCalls, 0);
  });

  testWidgets('countdown reaches expiry once and disposes safely',
      (tester) async {
    var elapsedCalls = 0;
    await tester.pumpWidget(
      themed(
        PaymentCountdown(
          expiresAt: DateTime.now().subtract(const Duration(milliseconds: 1)),
          onElapsed: () => elapsedCalls++,
        ),
      ),
    );

    await tester.pump();
    expect(elapsedCalls, 1);
    expect(find.text('00:00'), findsOneWidget);

    await tester.pumpWidget(themed(const SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 2));
    expect(elapsedCalls, 1);
  });

  testWidgets('success disables, dims and overlays the original QR',
      (tester) async {
    await tester.pumpWidget(
      themed(
        DeliveryPaymentQrCard(
          session: testPaymentSession(
            status: DeliveryPaymentStatus.success,
          ),
          status: DeliveryPaymentStatus.success,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(PaymentSuccessOverlay), findsOneWidget);
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(
      tester.widgetList<AbsorbPointer>(find.byType(AbsorbPointer)).any(
            (widget) => widget.absorbing,
          ),
      isTrue,
    );
  });
}
