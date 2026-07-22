import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/splash/screens/splash_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/session_restore_outcome.dart';
import 'package:delivery_partner_app/providers/authentication/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Returns a scripted sequence of results — one per call to
/// restoreSession(), holding on the last entry once exhausted — so a test
/// can simulate "offline, then retry succeeds" without any real network.
class FakeAuthSessionNotifier extends AuthSessionNotifier {
  FakeAuthSessionNotifier(this._results);

  final List<SessionRestoreResult> _results;
  int callCount = 0;

  @override
  Future<AuthSessionModel> build() async => AuthSessionModel.empty;

  @override
  Future<SessionRestoreResult> restoreSession() async {
    final index = callCount < _results.length ? callCount : _results.length - 1;
    callCount++;
    return _results[index];
  }
}

Widget buildApp(List<SessionRestoreResult> results) => ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(() => FakeAuthSessionNotifier(results)),
      ],
      child: GetMaterialApp(
        initialRoute: AppRoutes.splash,
        getPages: [
          GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
          GetPage(
              name: AppRoutes.dashboard,
              page: () => const Scaffold(body: Text('Dashboard Screen'))),
          GetPage(
              name: AppRoutes.verificationStatus,
              page: () =>
                  const Scaffold(body: Text('Verification Status Screen'))),
          GetPage(
              name: AppRoutes.personalInfo,
              page: () =>
                  const Scaffold(body: Text('Personal Details Screen'))),
          GetPage(
              name: AppRoutes.vehicleSelection,
              page: () =>
                  const Scaffold(body: Text('Vehicle Selection Screen'))),
          GetPage(
              name: AppRoutes.welcome,
              page: () => const Scaffold(body: Text('Welcome Screen'))),
        ],
      ),
    );

/// The splash screen's glow/logo/dots animations repeat indefinitely, so
/// `pumpAndSettle()` would hang for as long as it's on screen — advance
/// time with bounded `pump()` calls instead, exactly as the real
/// 2200ms-delay-then-260ms-transition timeline requires.
Future<void> settleBootstrap(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 2300));
  await tester.pump();
}

Future<void> settleTransition(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('active session restore navigates straight to the dashboard, no login',
      (tester) async {
    await tester.pumpWidget(buildApp([
      const SessionRestoreResult(SessionRestoreOutcome.active,
          route: AppRoutes.dashboard),
    ]));
    await settleBootstrap(tester);
    await settleTransition(tester);
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
    expect(find.text('Welcome Screen'), findsNothing);
  });

  testWidgets(
      'pending onboarding navigates to whatever route restoreSession already resolved — '
      'splash never derives its own destination',
      (tester) async {
    await tester.pumpWidget(buildApp([
      const SessionRestoreResult(SessionRestoreOutcome.needsOnboarding,
          route: AppRoutes.verificationStatus),
    ]));
    await settleBootstrap(tester);
    await settleTransition(tester);
    await tester.pumpAndSettle();

    expect(find.text('Verification Status Screen'), findsOneWidget);
  });

  testWidgets(
      'pending onboarding with a PROFILE route resumes exactly on Personal Details',
      (tester) async {
    await tester.pumpWidget(buildApp([
      const SessionRestoreResult(SessionRestoreOutcome.needsOnboarding,
          route: AppRoutes.personalInfo),
    ]));
    await settleBootstrap(tester);
    await settleTransition(tester);
    await tester.pumpAndSettle();

    expect(find.text('Personal Details Screen'), findsOneWidget);
  });

  testWidgets(
      'pending onboarding with a VEHICLE route resumes exactly on Vehicle Selection',
      (tester) async {
    await tester.pumpWidget(buildApp([
      const SessionRestoreResult(SessionRestoreOutcome.needsOnboarding,
          route: AppRoutes.vehicleSelection),
    ]));
    await settleBootstrap(tester);
    await settleTransition(tester);
    await tester.pumpAndSettle();

    expect(find.text('Vehicle Selection Screen'), findsOneWidget);
  });

  testWidgets('no/expired session restores to the welcome (login) screen',
      (tester) async {
    await tester.pumpWidget(buildApp([
      const SessionRestoreResult(SessionRestoreOutcome.loggedOut),
    ]));
    await settleBootstrap(tester);
    await settleTransition(tester);
    await tester.pumpAndSettle();

    expect(find.text('Welcome Screen'), findsOneWidget);
  });

  testWidgets('offline falls back to welcome instead of trapping the rider on splash',
      (tester) async {
    await tester.pumpWidget(buildApp([
      const SessionRestoreResult(SessionRestoreOutcome.offline),
    ]));
    await settleBootstrap(tester);
    await settleTransition(tester);
    await tester.pumpAndSettle();

    expect(find.text('Welcome Screen'), findsOneWidget);
    expect(find.text('Dashboard Screen'), findsNothing);
  });

  testWidgets('offline does not make a second session-restore attempt',
      (tester) async {
    await tester.pumpWidget(
      buildApp([
        const SessionRestoreResult(SessionRestoreOutcome.offline),
        const SessionRestoreResult(SessionRestoreOutcome.active,
            route: AppRoutes.dashboard),
      ]),
    );
    await settleBootstrap(tester);
    await settleTransition(tester);
    await tester.pumpAndSettle();

    expect(find.text('Welcome Screen'), findsOneWidget);
    expect(find.text('Dashboard Screen'), findsNothing);
  });
}
