// IncentivesScreen (reached via AppRoutes.incentives, e.g. MoreScreen's
// "Refer & earn" menu row) is a real referral screen backed by
// referralSummaryProvider — a reward-progress row, the rider's real
// referral code, and a "Invite on WhatsApp" share action. It no longer has
// a hardcoded referral code or a "Share Link with Friends" button (both
// replaced by the provider-driven _codeCard/_share flow), so the old
// assertions against that static content were stale; fixed to check the
// screen's real, provider-backed content instead.

import 'package:delivery_partner_app/core/theme/app_theme.dart';
import 'package:delivery_partner_app/features/earnings/screens/incentives_screen.dart';
import 'package:delivery_partner_app/models/referrals/referral_summary_model.dart';
import 'package:delivery_partner_app/providers/referrals/referral_provider.dart';
import 'package:delivery_partner_app/repositories/referrals/referral_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FakeReferralRepository implements ReferralRepository {
  FakeReferralRepository({required this.summary});
  final ReferralSummaryModel summary;

  @override
  Future<ReferralSummaryModel> getSummary() async => summary;

  @override
  Future<ReferralSummaryModel> applyCode(String code) async => summary;
}

Widget buildApp(ReferralSummaryModel summary, {TextScaler? textScaler}) =>
    ProviderScope(
      overrides: [
        referralRepositoryProvider
            .overrideWithValue(FakeReferralRepository(summary: summary)),
      ],
      child: GetMaterialApp(
        theme: AppTheme.light,
        builder: textScaler == null
            ? null
            : (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: child!,
                ),
        home: const IncentivesScreen(),
      ),
    );

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('cards reflow on a narrow phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildApp(
        const ReferralSummaryModel(
          referralCode: 'QIKPARTNER7700',
          rewardPaise: 20000,
          successfulDeliveries: 3,
          requiredSuccessfulDeliveries: 10,
          deliveriesRemaining: 7,
          lockedRewardPaise: 20000,
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    // At 320x568 with 2x text scale, the code card sits past the ListView's
    // default lazy-build cache extent — genuinely not built yet, not merely
    // scrolled off-screen — so it must be scrolled into view before it can
    // be found at all.
    await tester.scrollUntilVisible(find.text('QIKPARTNER7700'), 200);
    await tester.pumpAndSettle();
    expect(find.text('QIKPARTNER7700'), findsOneWidget);
    expect(find.text('Invite on WhatsApp'), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.helpCircle));
    await tester.pumpAndSettle();
    expect(find.text('Referral terms'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
