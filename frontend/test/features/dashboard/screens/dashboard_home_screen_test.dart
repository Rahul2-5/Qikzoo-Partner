import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/dashboard/screens/dashboard_home_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/dashboard/dashboard_stats_model.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';
import 'package:delivery_partner_app/models/orders/dispatch_offer_model.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/dashboard/dashboard_repository.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_image_picker.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_repository.dart';
import 'package:delivery_partner_app/repositories/orders/dispatch_repository.dart';

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({required this.initial});
  final DashboardStatsModel initial;
  DashboardStatsModel? current;
  Object? getStatsError;
  Object? toggleError;
  int getStatsCalls = 0;
  int goOnlineCalls = 0;
  int goOfflineCalls = 0;

  @override
  Future<DashboardStatsModel> getStats() async {
    getStatsCalls++;
    if (getStatsError != null) throw getStatsError!;
    return current ??= initial;
  }

  @override
  Future<DashboardStatsModel> goOnline() async {
    goOnlineCalls++;
    if (toggleError != null) throw toggleError!;
    current = (current ?? initial)
        .copyWith(availabilityStatus: RiderAvailabilityStatus.online);
    return current!;
  }

  @override
  Future<DashboardStatsModel> goOffline() async {
    goOfflineCalls++;
    if (toggleError != null) throw toggleError!;
    current = (current ?? initial)
        .copyWith(availabilityStatus: RiderAvailabilityStatus.offline);
    return current!;
  }
}

class FakeDispatchRepository implements DispatchRepository {
  FakeDispatchRepository({this.offer});
  DispatchOfferModel? offer;
  int getCurrentOfferCalls = 0;

  @override
  Future<DispatchOfferModel?> getCurrentOffer() async {
    getCurrentOfferCalls++;
    return offer;
  }

  @override
  Future<void> accept(String attemptId) => throw UnimplementedError();

  @override
  Future<void> reject(String attemptId) => throw UnimplementedError();
}

class FakeDocumentRepository implements DocumentRepository {
  List<DocumentModel> documents = const [
    DocumentModel(
      type: DocumentType.profilePhoto,
      status: DocumentStatus.notUploaded,
    ),
  ];

  @override
  Future<List<DocumentModel>> getDocuments() async => documents;

  @override
  Future<DocumentModel> uploadDocument(
      DocumentType type, String filePath) async {
    final uploaded = DocumentModel(
      type: type,
      status: DocumentStatus.pendingVerification,
      fileUrl: filePath,
    );
    documents = [uploaded];
    return uploaded;
  }
}

class FakeDocumentImagePicker implements DocumentImagePicker {
  @override
  Future<String?> pickImage(ImageSource source) async => '/tmp/selfie.jpg';
}

DispatchOfferModel mockOffer() => DispatchOfferModel(
      id: 'attempt-1',
      jobId: 'job-1',
      attemptNumber: 1,
      status: DispatchAttemptStatus.waitingRider,
      distanceKm: 2.0,
      searchRadiusKm: 5,
      broadcast: false,
      offeredAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(seconds: 20)),
    );

class FakeAuthRepository implements AuthRepository {
  bool loggedOut = false;

  @override
  Future<OtpModel> requestOtp(String phoneNumber) => throw UnimplementedError();

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp,
          {String? name}) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {
    loggedOut = true;
  }
}

DashboardStatsModel mockStats({
  RiderAvailabilityStatus availabilityStatus = RiderAvailabilityStatus.offline,
  double? acceptanceRatePercent = 92,
  double? completionRatePercent = 96,
  String? workingZone = 'Bengaluru, Karnataka',
}) =>
    DashboardStatsModel(
      riderName: 'Ravi Kumar',
      availabilityStatus: availabilityStatus,
      todaysEarningsPaise: 84200,
      todaysDeliveries: 14,
      walletBalancePaise: 312000,
      acceptanceRatePercent: acceptanceRatePercent,
      completionRatePercent: completionRatePercent,
      rating: 4.7,
      workingZone: workingZone,
    );

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp({
  required FakeDashboardRepository dashboardRepository,
  FakeAuthRepository? authRepository,
  FakeDispatchRepository? dispatchRepository,
}) {
  final documentRepository = FakeDocumentRepository();
  return ProviderScope(
    overrides: [
      dashboardRepositoryProvider.overrideWithValue(dashboardRepository),
      dispatchRepositoryProvider
          .overrideWithValue(dispatchRepository ?? FakeDispatchRepository()),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
      documentRepositoryProvider.overrideWithValue(documentRepository),
      documentImagePickerProvider.overrideWithValue(FakeDocumentImagePicker()),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.dashboard,
      getPages: [
        GetPage(
            name: AppRoutes.dashboard, page: () => const DashboardHomeScreen()),
        GetPage(
          name: AppRoutes.incomingOffer,
          page: () => const Scaffold(body: Text('Incoming Offer Screen')),
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

  testWidgets('loads and displays greeting, status, earnings, and every stat tile',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(initial: mockStats());
    await tester.pumpWidget(buildApp(dashboardRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(find.text('Offline'), findsWidgets);
    expect(find.textContaining('842'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.textContaining('3120'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('96%'), findsOneWidget);
    expect(find.text('4.7'), findsOneWidget);
    expect(find.text('Bengaluru, Karnataka'), findsOneWidget);
  });

  testWidgets('shows — for acceptance/completion rate and zone when null',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(
      initial: mockStats(
        acceptanceRatePercent: null,
        completionRatePercent: null,
        workingZone: null,
      ),
    );
    await tester.pumpWidget(buildApp(dashboardRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsNWidgets(3));
  });

  testWidgets('going online requires approval and a selfie before updating the chip',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(
        initial: mockStats(availabilityStatus: RiderAvailabilityStatus.offline));
    await tester.pumpWidget(buildApp(dashboardRepository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('availability-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Go online?'), findsOneWidget);
    expect(repo.goOnlineCalls, 0);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Quick selfie check'), findsOneWidget);

    await tester.tap(find.text('Take selfie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Photo'));
    await tester.pumpAndSettle();

    expect(repo.goOnlineCalls, 1);
    expect(find.text('Online'), findsWidgets);
  });

  testWidgets('tapping the toggle while online goes offline', (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(
        initial: mockStats(availabilityStatus: RiderAvailabilityStatus.online));
    await tester.pumpWidget(buildApp(dashboardRepository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('availability-toggle')));
    await tester.pumpAndSettle();

    expect(repo.goOfflineCalls, 1);
    expect(find.text('Offline'), findsWidgets);
  });

  testWidgets('a hard 401 on toggle logs the rider out and navigates to welcome',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(initial: mockStats())
      ..toggleError = const ApiException(message: 'Unauthorized', statusCode: 401);
    final authRepo = FakeAuthRepository();
    await tester.pumpWidget(
        buildApp(dashboardRepository: repo, authRepository: authRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('availability-toggle')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take selfie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Photo'));
    await tester.pumpAndSettle();

    expect(authRepo.loggedOut, isTrue);
    expect(find.text('Welcome Screen'), findsOneWidget);
  });

  testWidgets(
      'a non-401 error on toggle shows a snackbar and keeps existing stats visible',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(initial: mockStats())
      ..toggleError = const ApiException(
        message: 'Unable to connect. Check your internet connection.',
      );
    await tester.pumpWidget(buildApp(dashboardRepository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('availability-toggle')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take selfie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Photo'));
    await tester.pumpAndSettle();

    expect(find.textContaining("You're offline") , findsNothing);
    expect(find.textContaining('Unable to connect'), findsOneWidget);
    // The toggle failed, so status stays exactly as it was — no data lost.
    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(find.text('Offline'), findsWidgets);
  });

  testWidgets('a load failure shows Retry, which succeeds on retry', (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(initial: mockStats())
      ..getStatsError = const ApiException(
        message: 'Unable to connect. Check your internet connection.',
      );
    await tester.pumpWidget(buildApp(dashboardRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your dashboard'), findsOneWidget);

    repo.getStatsError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Ravi Kumar'), findsOneWidget);
  });

  testWidgets('pull-to-refresh reloads the dashboard', (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(initial: mockStats());
    await tester.pumpWidget(buildApp(dashboardRepository: repo));
    await tester.pumpAndSettle();

    final initialCalls = repo.getStatsCalls;
    final refreshIndicator =
        tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await refreshIndicator.onRefresh();
    await tester.pumpAndSettle();

    expect(repo.getStatsCalls, greaterThan(initialCalls));
  });

  testWidgets('navigates to the incoming offer screen when a dispatch offer appears',
      (tester) async {
    setTallSurface(tester);
    final dashboardRepo = FakeDashboardRepository(initial: mockStats());
    final dispatchRepo = FakeDispatchRepository(offer: mockOffer());
    await tester.pumpWidget(buildApp(
      dashboardRepository: dashboardRepo,
      dispatchRepository: dispatchRepo,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Incoming Offer Screen'), findsOneWidget);
  });

  testWidgets('stays on the dashboard when there is no dispatch offer', (tester) async {
    setTallSurface(tester);
    final dashboardRepo = FakeDashboardRepository(initial: mockStats());
    final dispatchRepo = FakeDispatchRepository(offer: null);
    await tester.pumpWidget(buildApp(
      dashboardRepository: dashboardRepo,
      dispatchRepository: dispatchRepo,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(find.text('Incoming Offer Screen'), findsNothing);
  });

  testWidgets('resuming the app after being backgrounded re-polls for an offer',
      (tester) async {
    setTallSurface(tester);
    final dashboardRepo = FakeDashboardRepository(initial: mockStats());
    final dispatchRepo = FakeDispatchRepository(offer: null);
    await tester.pumpWidget(buildApp(
      dashboardRepository: dashboardRepo,
      dispatchRepository: dispatchRepo,
    ));
    await tester.pumpAndSettle();

    final before = dispatchRepo.getCurrentOfferCalls;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(dispatchRepo.getCurrentOfferCalls, greaterThan(before));
  });
}
