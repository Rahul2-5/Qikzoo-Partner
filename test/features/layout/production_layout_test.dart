import 'package:delivery_partner_app/core/theme/app_theme.dart';
import 'package:delivery_partner_app/features/agreement/screens/agreement_screen.dart';
import 'package:delivery_partner_app/features/approval/screens/approval_screen.dart';
import 'package:delivery_partner_app/features/training/screens/training_screen.dart';
import 'package:delivery_partner_app/features/wallet/screens/wallet_screen.dart';
import 'package:delivery_partner_app/models/approval/approval_status_model.dart';
import 'package:delivery_partner_app/models/training/training_module_model.dart';
import 'package:delivery_partner_app/models/wallet/wallet_model.dart';
import 'package:delivery_partner_app/providers/approval/approval_provider.dart';
import 'package:delivery_partner_app/providers/training/training_provider.dart';
import 'package:delivery_partner_app/providers/wallet/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void setCompactSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp(Widget home, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(2),
        ),
        child: child!,
      ),
      home: home,
    ),
  );
}

class FakeTrainingModulesNotifier extends TrainingModulesNotifier {
  @override
  Future<List<TrainingModuleModel>> build() async => const [
        TrainingModuleModel(
          id: 'safety',
          title: 'Safe delivery practices for every road condition',
          description:
              'Learn how to prepare, ride, and complete deliveries safely during busy shifts.',
          durationMinutes: 15,
          isCompleted: false,
        ),
      ];
}

void main() {
  testWidgets('agreement options remain scrollable with large text',
      (tester) async {
    setCompactSurface(tester);

    await tester.pumpWidget(buildApp(const AgreementScreen()));
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pump();

    expect(
        find.text('I accept the Delivery Partner Agreement'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long approval copy remains inside its status card',
      (tester) async {
    setCompactSurface(tester);

    await tester.pumpWidget(
      buildApp(
        const ApprovalScreen(),
        overrides: [
          approvalStatusProvider.overrideWith(
            (ref) async => const ApprovalStatusModel(
              state: ApprovalState.rejected,
              rejectionReason:
                  'Please update the requested documents before submitting your application again.',
            ),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Application needs attention'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('training actions stack beside long module copy', (tester) async {
    setCompactSurface(tester);

    await tester.pumpWidget(
      buildApp(
        const TrainingScreen(),
        overrides: [
          trainingModulesProvider.overrideWith(FakeTrainingModulesNotifier.new),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Complete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wallet amounts and actions reflow with large text',
      (tester) async {
    setCompactSurface(tester);

    await tester.pumpWidget(
      buildApp(
        const WalletScreen(),
        overrides: [
          walletProvider.overrideWith(
            (ref) async => const WalletModel(
              balance: 123456789,
              pendingAmount: 9876543,
            ),
          ),
          transactionsProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Available balance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
