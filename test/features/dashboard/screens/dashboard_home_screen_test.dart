import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/dashboard/screens/dashboard_home_screen.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/capture_button.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/dashboard/dashboard_stats_model.dart';
import 'package:delivery_partner_app/models/notifications/notification_model.dart';
import 'package:delivery_partner_app/models/orders/dispatch_offer_model.dart';
import 'package:delivery_partner_app/models/partner_registration/personal_info_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/providers/core/camera_config_provider.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/dashboard/dashboard_repository.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_image_picker.dart';
import 'package:delivery_partner_app/repositories/orders/dispatch_repository.dart';
import 'package:delivery_partner_app/repositories/notifications/notifications_repository.dart';
import 'package:delivery_partner_app/repositories/profile/profile_repository.dart';

import '../../../support/fake_camera.dart';

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

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository(this.notifications);

  final List<NotificationModel> notifications;

  @override
  Future<List<NotificationModel>> getNotifications() async => notifications;

  @override
  Future<void> markAsRead(String id) async {}
}

class FakeProfileRepository implements ProfileRepository {
  int uploadSelfieCalls = 0;
  String? lastSelfiePath;
  Object? uploadSelfieError;

  @override
  Future<PartnerProfileModel> uploadSelfie(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    uploadSelfieCalls++;
    lastSelfiePath = file.path;
    if (uploadSelfieError != null) throw uploadSelfieError!;
    return PartnerProfileModel(
      id: 'rider-1',
      name: 'Ravi Kumar',
      phone: '9876543210',
      joinedDate: DateTime(2026, 1, 1),
      selfieUrl: file.path,
    );
  }

  @override
  Future<PartnerProfileModel> getProfile() => throw UnimplementedError();

  @override
  Future<RatingModel> getRating() => throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updatePersonalDetails({
    required String name,
    String? email,
    required DateTime dateOfBirth,
    required Gender gender,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> uploadProfilePhoto(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updateAddress({
    required String addressLine1,
    String? addressLine2,
    String? landmark,
    required String city,
    required String state,
    required String pincode,
    double? addressLat,
    double? addressLng,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updateEmergencyContact({
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) =>
      throw UnimplementedError();
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
      payout: 50,
      restaurantName: 'Test Restaurant',
      restaurantAddress: '1 Test Street',
      customerName: 'Test Customer',
      userAddress: '2 Test Avenue',
      dropDistanceKm: 3.0,
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
  NotificationsRepository? notificationsRepository,
  FakeProfileRepository? profileRepository,
}) {
  return ProviderScope(
    overrides: [
      dashboardRepositoryProvider.overrideWithValue(dashboardRepository),
      dispatchRepositoryProvider
          .overrideWithValue(dispatchRepository ?? FakeDispatchRepository()),
      if (notificationsRepository != null)
        notificationsRepositoryProvider
            .overrideWithValue(notificationsRepository),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
      profileRepositoryProvider
          .overrideWithValue(profileRepository ?? FakeProfileRepository()),
      documentImagePickerProvider.overrideWithValue(FakeDocumentImagePicker()),
      // Replaces only the native camera plugin — the rest of the selfie
      // flow (capture button, confirm sheet, upload) runs for real.
      cameraConfigProvider.overrideWithValue(
        CameraConfig(
          cameraListLoader: fakeCameraListLoader,
          controllerBuilder: (description) =>
              FakeCameraController(description),
        ),
      ),
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
        GetPage(
          name: AppRoutes.notifications,
          page: () => const Scaffold(body: Text('Notifications Screen')),
        ),
      ],
    ),
  );
}

/// The dashboard's real 8s dispatch-offer poll timer
/// (`AppConstants.dispatchOfferPollInterval`) is intentionally always
/// running (online or not — see its doc comment), which is correct
/// production behavior but means `pumpAndSettle()` — which waits for zero
/// scheduled frames — can never naturally converge once enough cumulative
/// virtual test time has elapsed for that periodic timer to fire mid-settle.
/// Bounded pumps sidestep that without touching the real polling behavior.
Future<void> pumpBounded(WidgetTester tester) async {
  await tester.pump();
  // 20 x 100ms = 2s of virtual time — comfortably enough for the fake
  // repositories' near-instant futures plus any transition animations to
  // finish, while staying well under the 8s poll interval so this loop
  // can never race the periodic timer the way pumpAndSettle() does.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Taps the real selfie [CaptureButton], which drives a real (unfaked)
/// `dart:io` file read/write via `SelfieImageProcessor.prepareForUpload`.
/// The virtualized test clock that `pump()` advances can't move that real
/// I/O forward, so the tap — and the async work it kicks off — must happen
/// inside `runAsync`, Flutter's documented escape hatch for letting genuine
/// async work complete inside an otherwise clock-faked widget test.
Future<void> tapCaptureButton(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.byType(CaptureButton));
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await pumpBounded(tester);
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('loads the compact rider overview without the legacy stat grid',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(
      initial: mockStats(availabilityStatus: RiderAvailabilityStatus.online),
    );
    await tester.pumpWidget(buildApp(dashboardRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Qikzoo'), findsOneWidget);
    expect(find.text('You are Online'), findsOneWidget);
    expect(find.text('Go offline'), findsOneWidget);
    expect(find.textContaining('842'), findsWidgets);
    expect(find.text('14'), findsWidgets);
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('4.7'), findsOneWidget);
    expect(find.text('Wallet balance'), findsNothing);
    expect(find.text('Completion rate'), findsNothing);
    expect(find.text('Working zone'), findsNothing);
    expect(find.text("TODAY'S PROGRESS"), findsOneWidget);
    expect(find.text('Top opportunities'), findsNothing);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Incentives'), findsOneWidget);
    expect(find.text('Performance'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
  });

  testWidgets('keeps earnings and gig content hidden while offline',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(
      buildApp(
        dashboardRepository: FakeDashboardRepository(initial: mockStats()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You are Offline'), findsOneWidget);
    expect(find.text("Today's Overview"), findsNothing);
    expect(find.text("TODAY'S PROGRESS"), findsNothing);
    expect(find.text('Top opportunities'), findsNothing);
  });

  testWidgets('shows the unread notification count and opens notifications',
      (tester) async {
    // bySemanticsLabel needs the semantics tree actually built — Flutter
    // widget tests don't generate it by default.
    final semantics = tester.ensureSemantics();
    setTallSurface(tester);
    final notifications = FakeNotificationsRepository([
      NotificationModel(
        id: 'unread-1',
        title: 'New gig',
        body: '',
        isRead: false,
        createdAt: DateTime.now(),
        type: NotificationType.order,
      ),
      NotificationModel(
        id: 'unread-2',
        title: 'New bonus',
        body: '',
        isRead: false,
        createdAt: DateTime.now(),
        type: NotificationType.earnings,
      ),
    ]);
    await tester.pumpWidget(
      buildApp(
        dashboardRepository: FakeDashboardRepository(initial: mockStats()),
        notificationsRepository: notifications,
      ),
    );
    await tester.pumpAndSettle();

    // The button's Semantics doesn't set `container: true`, so its label
    // merges with the descendant unread-count Text's own semantics (a
    // trailing "\n2") rather than staying exactly "Notifications, 2 unread".
    final notificationButtonLabel = RegExp(r'^Notifications, 2 unread\n2$');
    expect(find.bySemanticsLabel(notificationButtonLabel), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(notificationButtonLabel));
    await tester.pumpAndSettle();
    expect(find.text('Notifications Screen'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('shows — for acceptance/completion rate and zone when null',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(
      initial: mockStats(
        availabilityStatus: RiderAvailabilityStatus.online,
        acceptanceRatePercent: null,
        completionRatePercent: null,
        workingZone: null,
      ),
    );
    await tester.pumpWidget(buildApp(dashboardRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
  });

  testWidgets(
      'going online requires approval and a selfie before updating the chip',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(
        initial:
            mockStats(availabilityStatus: RiderAvailabilityStatus.offline));
    final profileRepo = FakeProfileRepository();
    await tester.pumpWidget(
        buildApp(dashboardRepository: repo, profileRepository: profileRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('availability-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Go online?'), findsOneWidget);
    expect(repo.goOnlineCalls, 0);

    await tester.tap(find.text('Confirm'));
    await pumpBounded(tester);
    expect(find.text('Quick selfie check'), findsOneWidget);

    await tester.tap(find.text('Take selfie'));
    await pumpBounded(tester);
    // Camera screen is pushed and the fake camera has initialized; capture
    // a frame before the confirm sheet can appear.
    await tapCaptureButton(tester);
    await tester.tap(find.text('Use Photo'));
    await pumpBounded(tester);

    // The selfie must actually be captured and uploaded through the real
    // profile API — not silently faked — before the rider is allowed online.
    expect(profileRepo.uploadSelfieCalls, 1);
    expect(profileRepo.lastSelfiePath, isNotNull);
    expect(profileRepo.lastSelfiePath, endsWith('selfie.jpg'));
    expect(repo.goOnlineCalls, 1);
    expect(find.text('You are Online'), findsOneWidget);
    expect(find.text('Go offline'), findsOneWidget);
    expect(find.text("TODAY'S PROGRESS"), findsOneWidget);
    expect(find.text("Today's Overview"), findsOneWidget);
    expect(find.text('Top opportunities'), findsNothing);
    expect(find.byKey(const Key('online-status-celebration')), findsOneWidget);
  });

  testWidgets(
      'a failed selfie upload keeps the rider offline and shows a retry message',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(
        initial:
            mockStats(availabilityStatus: RiderAvailabilityStatus.offline));
    final profileRepo = FakeProfileRepository()
      ..uploadSelfieError = Exception('network down');
    await tester.pumpWidget(
        buildApp(dashboardRepository: repo, profileRepository: profileRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('availability-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await pumpBounded(tester);
    await tester.tap(find.text('Take selfie'));
    await pumpBounded(tester);
    await tapCaptureButton(tester);
    await tester.tap(find.text('Use Photo'));
    await pumpBounded(tester);

    expect(profileRepo.uploadSelfieCalls, 1);
    expect(find.textContaining('Upload failed'), findsOneWidget);
    // Availability must never be toggled when the selfie upload fails — the
    // rider stays exactly where the failed upload left them (still on the
    // selfie screen, free to retry) rather than being bounced online.
    expect(repo.goOnlineCalls, 0);
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
    expect(find.text('You are Offline'), findsOneWidget);
  });

  testWidgets(
      'a hard 401 on toggle logs the rider out and navigates to welcome',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(initial: mockStats())
      ..toggleError =
          const ApiException(message: 'Unauthorized', statusCode: 401);
    final authRepo = FakeAuthRepository();
    await tester.pumpWidget(
        buildApp(dashboardRepository: repo, authRepository: authRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('availability-toggle')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await pumpBounded(tester);
    await tester.tap(find.text('Take selfie'));
    await pumpBounded(tester);
    await tapCaptureButton(tester);
    await tester.tap(find.text('Use Photo'));
    await pumpBounded(tester);

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
    await pumpBounded(tester);
    await tester.tap(find.text('Take selfie'));
    await pumpBounded(tester);
    await tapCaptureButton(tester);
    await tester.tap(find.text('Use Photo'));
    await pumpBounded(tester);

    expect(find.textContaining("You're offline"), findsNothing);
    expect(find.textContaining('Unable to connect'), findsOneWidget);
    // The toggle failed, so status stays exactly as it was — no data lost.
    expect(find.text('Qikzoo'), findsOneWidget);
    expect(find.text('You are Offline'), findsOneWidget);
  });

  testWidgets('a load failure shows Retry, which succeeds on retry',
      (tester) async {
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

    expect(find.text('Qikzoo'), findsOneWidget);
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

  testWidgets(
      'navigates to the incoming offer screen when a dispatch offer appears',
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

  testWidgets('stays on the dashboard when there is no dispatch offer',
      (tester) async {
    setTallSurface(tester);
    final dashboardRepo = FakeDashboardRepository(initial: mockStats());
    final dispatchRepo = FakeDispatchRepository(offer: null);
    await tester.pumpWidget(buildApp(
      dashboardRepository: dashboardRepo,
      dispatchRepository: dispatchRepo,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Qikzoo'), findsOneWidget);
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
