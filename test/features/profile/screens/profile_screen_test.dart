// This file used to mount `ProfileScreen` at `AppRoutes.profile` and assert
// on a sectioned menu ("Gigs history", "Trips history", "Your offers",
// "Your benefits", referral bonus, "Rent an EV", etc.) that does not exist
// anywhere in current production code, tapping "Home" to reach the
// dashboard, and a "Logout" button on that same screen.
//
// Investigating the real route table (lib/core/routes/app_pages.dart) found:
//   - `AppRoutes.profile` ('/profile') actually serves `MoreScreen`
//     (lib/features/profile/screens/more_screen.dart) — the real bottom-tab
//     "Profile" destination. Its menu is three sections (Account / Partner
//     tools / Preferences) with entries like "My profile", "Help & support",
//     "Refer & earn", "Notifications", "Wrong action", "Login history",
//     "Legal", "Settings" — none of which match this file's old assertions,
//     and it has no Logout button at all.
//   - `AppRoutes.myProfile` ('/profile/my-profile') serves the real
//     `ProfileScreen` (lib/features/profile/screens/profile_screen.dart) —
//     a partner-details card (avatar, DE ID, mobile, joining date, city,
//     documents/emergency/bank/language/terms/support menu) that DOES have
//     the "Logout" button with a confirmation dialog this file tested, just
//     reachable at a different route than the one this file assumed.
//
// So the old file was pointed at the wrong screen entirely (mounting
// ProfileScreen under the AppRoutes.profile route it does not occupy in
// production, then asserting on menu copy belonging to neither real
// screen). Fixed by testing each real screen at its real route instead of
// inventing new production UI to match the stale assertions.

import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/profile/screens/more_screen.dart';
import 'package:delivery_partner_app/features/profile/screens/profile_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/profile_summary.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/providers/profile/profile_provider.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class FakeAuthRepository implements AuthRepository {
  bool loggedOut = false;

  @override
  Future<OtpModel> requestOtp(String phoneNumber) => throw UnimplementedError();

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp,
          {String? name}) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async => loggedOut = true;
}

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const profileSummary = ProfileSummary(
  name: 'Rahul Verma',
  partnerId: 'ZP12345678',
  ratingAverage: 4.8,
  deliveriesLabel: '250+ Deliveries',
  documentsVerified: true,
  walletBalance: 8750,
  pendingAmount: 1250,
  notificationCount: 3,
);

/// Mounts the real bottom-tab "Profile" destination: `MoreScreen` at
/// `AppRoutes.profile`.
Widget buildMoreScreenApp() => ProviderScope(
      overrides: [
        profileSummaryProvider
            .overrideWith((ref) => const AsyncData(profileSummary)),
      ],
      child: GetMaterialApp(
        initialRoute: AppRoutes.profile,
        getPages: [
          GetPage(name: AppRoutes.profile, page: () => const MoreScreen()),
          GetPage(
              name: AppRoutes.dashboard,
              page: () => const Scaffold(body: Text('Dashboard Screen'))),
          GetPage(
              name: AppRoutes.myProfile,
              page: () => const Scaffold(body: Text('My Profile Screen'))),
          GetPage(
              name: AppRoutes.ticketList,
              page: () => const Scaffold(body: Text('Ticket List Screen'))),
          GetPage(
              name: AppRoutes.incentives,
              page: () => const Scaffold(body: Text('Incentives Screen'))),
          GetPage(
              name: AppRoutes.notifications,
              page: () => const Scaffold(body: Text('Notifications Screen'))),
          GetPage(
              name: AppRoutes.wrongAction,
              page: () => const Scaffold(body: Text('Wrong Action Screen'))),
          GetPage(
              name: AppRoutes.loginHistory,
              page: () => const Scaffold(body: Text('Login History Screen'))),
          GetPage(
              name: AppRoutes.agreement,
              page: () => const Scaffold(body: Text('Agreement Screen'))),
          GetPage(
              name: AppRoutes.settings,
              page: () => const Scaffold(body: Text('Settings Screen'))),
        ],
      ),
    );

/// Mounts the real "My profile" detail screen: `ProfileScreen` at
/// `AppRoutes.myProfile` — reached from MoreScreen's "My profile" row, and
/// the screen that actually owns the Logout button this file tests.
Widget buildProfileDetailApp({AuthRepository? authRepository}) => ProviderScope(
      overrides: [
        profileProvider.overrideWith((ref) async => PartnerProfileModel(
              id: 'rider-1',
              publicRiderId: 'QRID34174427',
              name: 'Rahul Verma',
              phone: '9876543210',
              joinedDate: DateTime(2026, 1, 15),
              city: 'Mumbai',
            )),
        ratingProvider
            .overrideWith((ref) async => const RatingModel(average: 4.8, totalRatings: 250)),
        authRepositoryProvider
            .overrideWithValue(authRepository ?? FakeAuthRepository()),
      ],
      child: GetMaterialApp(
        initialRoute: AppRoutes.myProfile,
        getPages: [
          GetPage(name: AppRoutes.myProfile, page: () => const ProfileScreen()),
          GetPage(
              name: AppRoutes.welcome,
              page: () => const Scaffold(body: Text('Welcome Screen'))),
        ],
      ),
    );

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  group('MoreScreen (Profile tab)', () {
    testWidgets('renders the profile hero and the real menu sections',
        (tester) async {
      setTallSurface(tester);
      await tester.pumpWidget(buildMoreScreenApp());
      await tester.pumpAndSettle();

      expect(find.text('Rahul Verma'), findsOneWidget);
      expect(find.textContaining('ZP12345678'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('250+ Deliveries'), findsOneWidget);
      for (final title in [
        'My profile',
        'Help & support',
        'Refer & earn',
        'Notifications',
        'Wrong action',
        'Login history',
        'Legal',
        'Settings',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('My profile navigates to the profile detail route',
        (tester) async {
      setTallSurface(tester);
      await tester.pumpWidget(buildMoreScreenApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('My profile'));
      await tester.pumpAndSettle();

      expect(find.text('My Profile Screen'), findsOneWidget);
    });

    testWidgets('Settings row navigates to the settings route', (tester) async {
      setTallSurface(tester);
      await tester.pumpWidget(buildMoreScreenApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets('Legal row navigates to the agreement route', (tester) async {
      setTallSurface(tester);
      await tester.pumpWidget(buildMoreScreenApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Legal'));
      await tester.pumpAndSettle();

      expect(find.text('Agreement Screen'), findsOneWidget);
    });

    testWidgets('Home tab navigates to the dashboard', (tester) async {
      setTallSurface(tester);
      await tester.pumpWidget(buildMoreScreenApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Screen'), findsOneWidget);
    });
  });

  group('ProfileScreen (My profile detail)', () {
    testWidgets('Log Out opens confirmation and returns to welcome on confirm',
        (tester) async {
      setTallSurface(tester);
      final fakeAuth = FakeAuthRepository();
      await tester.pumpWidget(buildProfileDetailApp(authRepository: fakeAuth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Screen'), findsOneWidget);
      expect(fakeAuth.loggedOut, isTrue);
    });

    testWidgets('Log Out cancel keeps the rider signed in', (tester) async {
      setTallSurface(tester);
      final fakeAuth = FakeAuthRepository();
      await tester.pumpWidget(buildProfileDetailApp(authRepository: fakeAuth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Screen'), findsNothing);
      expect(fakeAuth.loggedOut, isFalse);
    });
  });
}
