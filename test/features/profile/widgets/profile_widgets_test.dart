import 'package:delivery_partner_app/core/theme/app_theme.dart';
import 'package:delivery_partner_app/features/profile/widgets/profile_header.dart';
import 'package:delivery_partner_app/features/profile/widgets/profile_identity_card.dart';
import 'package:delivery_partner_app/features/profile/widgets/profile_learning_section.dart';
import 'package:delivery_partner_app/features/profile/widgets/profile_menu_tile.dart';
import 'package:delivery_partner_app/features/profile/widgets/personal_information_sheet.dart';
import 'package:delivery_partner_app/features/profile/widgets/verification_banner.dart';
import 'package:delivery_partner_app/features/profile/widgets/wallet_balance_card.dart';
import 'package:delivery_partner_app/models/profile/profile_summary.dart';
import 'package:delivery_partner_app/models/training/training_module_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );

void main() {
  final summary = ProfileSummary.mock();

  test('ProfileSummary.mock returns the documented partner data', () {
    expect(summary.name, 'Rahul Verma');
    expect(summary.partnerId, 'ZP12345678');
    expect(summary.ratingAverage, 4.8);
    expect(summary.walletBalance, 2345.50);
    expect(summary.notificationCount, 3);
  });

  testWidgets('ProfileIdentityCard renders summary and handles stats tap',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(ProfileIdentityCard(
      summary: summary,
      onViewStats: () => tapped = true,
    )));

    expect(find.text('Rahul Verma'), findsOneWidget);
    expect(find.text('Delivery Partner ID: ZP12345678'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('250+ Deliveries'), findsOneWidget);

    await tester.tap(find.text('View Stats'));
    expect(tapped, isTrue);
  });

  testWidgets('WalletBalanceCard renders balance details and handles withdraw',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(WalletBalanceCard(
      summary: summary,
      onWithdraw: () => tapped = true,
    )));

    expect(find.text('Wallet Balance'), findsOneWidget);
    expect(find.text('₹2,345.50'), findsOneWidget);
    expect(find.text('HDFC Bank ····4321'), findsOneWidget);
    expect(find.text('Next payout: 15 May 2025'), findsOneWidget);

    await tester.tap(find.text('Withdraw'));
    expect(tapped, isTrue);
  });

  testWidgets('VerificationBanner exposes its verified state and callback',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(VerificationBanner(
      verified: true,
      onTap: () => tapped = true,
    )));

    expect(find.text('Documents Verified'), findsOneWidget);
    expect(find.text('All your documents are verified'), findsOneWidget);
    await tester.tap(find.text('Documents Verified'));
    expect(tapped, isTrue);
  });

  testWidgets('ProfileMenuTile hides the chevron for destructive actions',
      (tester) async {
    await tester.pumpWidget(wrap(ProfileMenuTile(
      icon: LucideIcons.logOut,
      title: 'Log Out',
      subtitle: 'Log out from your account',
      destructive: true,
      onTap: () {},
    )));

    expect(find.text('Log Out'), findsOneWidget);
    expect(find.text('Log out from your account'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
  });

  testWidgets('ProfileHeader shows the notification count and handles tap',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(ProfileHeader(
      notificationCount: 3,
      onNotifications: () => tapped = true,
    )));

    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byTooltip('Notifications'));
    expect(tapped, isTrue);
  });

  testWidgets('ProfileLearningSection shows videos and handles a video tap',
      (tester) async {
    TrainingModuleModel? selectedModule;
    const module = TrainingModuleModel(
      id: 'safe-food-delivery',
      title: 'Safe Food Delivery',
      description: 'Keep every order fresh, sealed, and spill-free.',
      durationMinutes: 4,
      isCompleted: false,
    );

    await tester.pumpWidget(wrap(ProfileLearningSection(
      modules: const [module],
      onModuleTap: (value) => selectedModule = value,
    )));

    expect(find.text('Learnings'), findsOneWidget);
    expect(find.text('Safe Food Delivery'), findsOneWidget);
    expect(find.text('4 min'), findsOneWidget);

    await tester.tap(find.text('Safe Food Delivery'));
    expect(selectedModule, module);
  });

  testWidgets('PersonalInformationSheet switches to edit mode', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(const PersonalInformationSheet(
      information: mockPersonalInformation,
    )));

    expect(find.text('Your account and contact details'), findsOneWidget);
    expect(find.text('Rahul Verma'), findsWidgets);
    expect(find.text('Edit information'), findsOneWidget);

    await tester.tap(find.text('Edit information'));
    await tester.pump();

    expect(find.text('Update the details you want to change'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
