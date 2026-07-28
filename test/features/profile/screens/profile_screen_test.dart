import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/profile/screens/profile_screen.dart';
import 'package:delivery_partner_app/features/profile/widgets/personal_information_sheet.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/profile/profile_summary.dart';
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

Widget buildApp({AuthRepository? authRepository}) => ProviderScope(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(authRepository ?? FakeAuthRepository()),
        profileSummaryProvider
            .overrideWith((ref) => const AsyncData(profileSummary)),
        personalInformationProvider
            .overrideWith((ref) => mockPersonalInformation),
      ],
      child: GetMaterialApp(
        initialRoute: AppRoutes.profile,
        getPages: [
          GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
          GetPage(
              name: AppRoutes.dashboard,
              page: () => const Scaffold(body: Text('Dashboard Screen'))),
          GetPage(
              name: AppRoutes.earnings,
              page: () => const Scaffold(body: Text('Earnings Screen'))),
          GetPage(
              name: AppRoutes.orders,
              page: () => const Scaffold(body: Text('Orders Screen'))),
          GetPage(
              name: AppRoutes.settings,
              page: () => const Scaffold(body: Text('Settings Screen'))),
          GetPage(
              name: AppRoutes.welcome,
              page: () => const Scaffold(body: Text('Welcome Screen'))),
        ],
      ),
    );

void main() {
  testWidgets('ProfileScreen renders the requested sectioned menu',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());

    expect(find.text('Rahul Verma'), findsOneWidget);
    for (final title in [
      'Gigs history',
      'Trips history',
      'Up to ₹2,000 referral bonus',
      'Support',
      'Help centre',
      'Support tickets',
      'Partner options',
      'Rest points',
      'Your benefits',
      'Doctor visit at store',
      'Medical insurance',
      'Scratch cards',
      'Agreement',
      'App settings',
      'App language',
      'Audio language',
      'Support language',
      'Order alert sound',
      'Logout',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('Settings menu navigates to the settings route', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('App language'));
    await tester.pumpAndSettle();

    expect(find.text('Settings Screen'), findsOneWidget);
  });

  testWidgets('Tapping the profile summary opens the partner ID',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('Rahul Verma'));
    await tester.pumpAndSettle();

    expect(find.text('DELIVERY PARTNER'), findsOneWidget);
    expect(find.text('Essential services · Food delivery'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Currently not delivering any order'), findsOneWidget);
  });

  testWidgets('Home tab navigates to the dashboard', (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
  });

  testWidgets('Log Out opens confirmation and returns to welcome on confirm',
      (tester) async {
    setTallSurface(tester);
    final fakeAuth = FakeAuthRepository();
    await tester.pumpWidget(buildApp(authRepository: fakeAuth));
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
    await tester.pumpWidget(buildApp(authRepository: fakeAuth));
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Screen'), findsNothing);
    expect(fakeAuth.loggedOut, isFalse);
  });
}
