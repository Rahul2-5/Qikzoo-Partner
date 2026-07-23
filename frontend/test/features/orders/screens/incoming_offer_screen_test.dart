import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/orders/screens/incoming_offer_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/orders/dispatch_offer_model.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/orders/dispatch_repository.dart';

class FakeDispatchRepository implements DispatchRepository {
  FakeDispatchRepository({this.initial});
  DispatchOfferModel? initial;
  DispatchOfferModel? current;
  Object? acceptError;
  Object? rejectError;
  int acceptCalls = 0;
  int rejectCalls = 0;
  String? lastAcceptedId;
  String? lastRejectedId;

  @override
  Future<DispatchOfferModel?> getCurrentOffer() async => current ??= initial;

  @override
  Future<void> accept(String attemptId) async {
    acceptCalls++;
    lastAcceptedId = attemptId;
    if (acceptError != null) throw acceptError!;
  }

  @override
  Future<void> reject(String attemptId) async {
    rejectCalls++;
    lastRejectedId = attemptId;
    if (rejectError != null) throw rejectError!;
  }
}

class FakeAuthRepository implements AuthRepository {
  bool loggedOut = false;

  @override
  Future<OtpModel> requestOtp(String phoneNumber) => throw UnimplementedError();

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp, {String? name}) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {
    loggedOut = true;
  }
}

DispatchOfferModel mockOffer({
  String id = 'attempt-1',
  bool broadcast = false,
  Duration remaining = const Duration(seconds: 20),
  double distanceKm = 2.5,
}) =>
    DispatchOfferModel(
      id: id,
      jobId: 'job-1',
      attemptNumber: 1,
      status: DispatchAttemptStatus.waitingRider,
      distanceKm: distanceKm,
      searchRadiusKm: 5,
      broadcast: broadcast,
      offeredAt: DateTime.now(),
      expiresAt: DateTime.now().add(remaining),
    );

Widget buildApp({
  required DispatchRepository dispatchRepository,
  FakeAuthRepository? authRepository,
}) {
  return ProviderScope(
    overrides: [
      dispatchRepositoryProvider.overrideWithValue(dispatchRepository),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.incomingOffer,
      getPages: [
        GetPage(
            name: AppRoutes.incomingOffer, page: () => const IncomingOfferScreen()),
        GetPage(
          name: AppRoutes.activeOrder,
          page: () => const Scaffold(body: Text('Active Order Screen')),
        ),
        GetPage(
          name: AppRoutes.welcome,
          page: () => const Scaffold(body: Text('Welcome Screen')),
        ),
      ],
    ),
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('shows the offer distance, countdown, and accept/reject actions',
      (tester) async {
    final repo = FakeDispatchRepository(initial: mockOffer());
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();

    expect(find.text('New delivery request'), findsOneWidget);
    expect(find.textContaining('2.5 km'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.textContaining('00:'), findsOneWidget);
  });

  testWidgets('shows a broadcast indicator when the offer was sent to several riders',
      (tester) async {
    final repo = FakeDispatchRepository(initial: mockOffer(broadcast: true));
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();

    expect(find.text('Offered to several riders'), findsOneWidget);
  });

  testWidgets('accepting navigates to the active order screen', (tester) async {
    final repo = FakeDispatchRepository(initial: mockOffer());
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(repo.acceptCalls, 1);
    expect(repo.lastAcceptedId, 'attempt-1');
    expect(find.text('Active Order Screen'), findsOneWidget);
  });

  testWidgets('rejecting returns to the previous screen', (tester) async {
    final repo = FakeDispatchRepository(initial: mockOffer());
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    expect(repo.rejectCalls, 1);
    expect(find.text('New delivery request'), findsNothing);
  });

  testWidgets('does not double-submit accept on rapid duplicate taps', (tester) async {
    final repo = FakeDispatchRepository(initial: mockOffer());
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();

    await tester.tap(find.text('Accept'));
    await tester.tap(find.text('Accept'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(repo.acceptCalls, 1);
  });

  testWidgets('a failed accept shows an error and keeps the offer visible', (tester) async {
    final repo = FakeDispatchRepository(initial: mockOffer())
      ..acceptError = const ApiException(message: 'This offer is no longer available.');
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(find.textContaining('This offer is no longer available'), findsOneWidget);
    expect(find.text('New delivery request'), findsOneWidget);
  });

  testWidgets('a 401 on accept logs the rider out and navigates to welcome', (tester) async {
    final repo = FakeDispatchRepository(initial: mockOffer())
      ..acceptError = const ApiException(message: 'Unauthorized', statusCode: 401);
    final authRepo = FakeAuthRepository();
    await tester
        .pumpWidget(buildApp(dispatchRepository: repo, authRepository: authRepo));
    await tester.pump();

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(authRepo.loggedOut, isTrue);
    expect(find.text('Welcome Screen'), findsOneWidget);
  });

  testWidgets('an already-expired offer shows the expired state immediately',
      (tester) async {
    final repo = FakeDispatchRepository(
      initial: mockOffer(remaining: const Duration(seconds: -5)),
    );
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();

    expect(find.text('This offer has expired.'), findsOneWidget);
    expect(find.text('Accept'), findsNothing);
  });

  testWidgets('no offer at all shows the "no longer available" state', (tester) async {
    final repo = FakeDispatchRepository(initial: null);
    await tester.pumpWidget(buildApp(dispatchRepository: repo));
    await tester.pump();

    expect(find.text('This offer is no longer available.'), findsOneWidget);
  });

  testWidgets('a load failure shows Retry, which succeeds on retry', (tester) async {
    final repo = FakeDispatchRepository()..current = null;
    // Force the initial build to fail by throwing from getCurrentOffer once.
    var callCount = 0;
    final failingRepo = _ThrowOnceThenSucceed(repo, () => callCount++ == 0);
    await tester.pumpWidget(buildApp(dispatchRepository: failingRepo));
    await tester.pump();

    expect(find.textContaining('Unable to connect'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('This offer is no longer available.'), findsOneWidget);
  });
}

class _ThrowOnceThenSucceed implements DispatchRepository {
  _ThrowOnceThenSucceed(this._delegate, this._shouldThrow);
  final DispatchRepository _delegate;
  final bool Function() _shouldThrow;

  @override
  Future<DispatchOfferModel?> getCurrentOffer() async {
    if (_shouldThrow()) {
      throw const ApiException(message: 'Unable to connect. Check your internet connection.');
    }
    return _delegate.getCurrentOffer();
  }

  @override
  Future<void> accept(String attemptId) => _delegate.accept(attemptId);

  @override
  Future<void> reject(String attemptId) => _delegate.reject(attemptId);
}
