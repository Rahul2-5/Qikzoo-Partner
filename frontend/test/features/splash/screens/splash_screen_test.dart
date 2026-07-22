import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/splash/screens/splash_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/session_restore_outcome.dart';
import 'package:delivery_partner_app/providers/authentication/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Returns a scripted sequence of outcomes — one per call to
/// restoreSession(), holding on the last entry once exhausted — so a test
/// can simulate "offline, then retry succeeds" without any real network.
class FakeAuthSessionNotifier extends AuthSessionNotifier {
  FakeAuthSessionNotifier(this._outcomes);

  final List<SessionRestoreOutcome> _outcomes;
  int callCount = 0;

  @override
  Future<AuthSessionModel> build() async => AuthSessionModel.empty;

  @override
  Future<SessionRestoreOutcome> restoreSession() async {
    final index = callCount < _outcomes.length ? callCount : _outcomes.length - 1;
    callCount++;
    return _outcomes[index];
  }
}

Widget buildApp(List<SessionRestoreOutcome> outcomes) => ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(() => FakeAuthSessionNotifier(outcomes)),
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
    await tester.pumpWidget(buildApp([SessionRestoreOutcome.active]));
    await settleBootstrap(tester);
    await settleTransition(tester);
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
    expect(find.text('Welcome Screen'), findsNothing);
  });

  testWidgets('pending onboarding restores to the verification status screen',
      (tester) async {
    await tester.pumpWidget(buildApp([SessionRestoreOutcome.needsOnboarding]));
    await settleBootstrap(tester);
    await settleTransition(tester);
    await tester.pumpAndSettle();

    expect(find.text('Verification Status Screen'), findsOneWidget);
  });

  testWidgets('no/expired session restores to the welcome (login) screen',
      (tester) async {
    await tester.pumpWidget(buildApp([SessionRestoreOutcome.loggedOut]));
    await settleBootstrap(tester);
    await settleTransition(tester);
    await tester.pumpAndSettle();

    expect(find.text('Welcome Screen'), findsOneWidget);
  });

  testWidgets('offline keeps the rider on the splash screen with a retry action, no login shown',
      (tester) async {
    await tester.pumpWidget(buildApp([SessionRestoreOutcome.offline]));
    await settleBootstrap(tester);

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Welcome Screen'), findsNothing);
    expect(find.text('Dashboard Screen'), findsNothing);
  });

  testWidgets('retry after offline navigates once connectivity is restored',
      (tester) async {
    await tester.pumpWidget(
      buildApp([SessionRestoreOutcome.offline, SessionRestoreOutcome.active]),
    );
    await settleBootstrap(tester);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await settleTransition(tester);
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
  });
}
