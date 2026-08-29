import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/location/location_platform.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/dashboard/screens/dashboard_home_screen.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/capture_button.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/dashboard/dashboard_stats_model.dart';
import 'package:delivery_partner_app/models/location/rider_location_ping.dart';
import 'package:delivery_partner_app/models/orders/dispatch_offer_model.dart';
import 'package:delivery_partner_app/models/orders/order_history_page_model.dart';
import 'package:delivery_partner_app/models/orders/rider_order_model.dart';
import 'package:delivery_partner_app/models/partner_registration/personal_info_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/providers/core/camera_config_provider.dart';
import 'package:delivery_partner_app/providers/orders/dispatch_offer_provider.dart';
import 'package:delivery_partner_app/core/storage/dispatch_offer_cache.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/dashboard/dashboard_repository.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_image_picker.dart';
import 'package:delivery_partner_app/repositories/location/location_repository.dart';
import 'package:delivery_partner_app/repositories/orders/dispatch_repository.dart';
import 'package:delivery_partner_app/repositories/orders/rider_orders_repository.dart';
import 'package:delivery_partner_app/repositories/profile/profile_repository.dart';

import '../../../support/fake_camera.dart';

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({required this.initial});
  final DashboardStatsModel initial;
  DashboardStatsModel? current;
  Object? getStatsError;
  Object? toggleError;
  Object? goAvailableError;
  int getStatsCalls = 0;
  int goOnlineCalls = 0;
  int goAvailableCalls = 0;
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
  Future<DashboardStatsModel> goAvailable() async {
    goAvailableCalls++;
    if (goAvailableError != null) throw goAvailableError!;
    if (toggleError != null) throw toggleError!;
    current = (current ?? initial)
        .copyWith(availabilityStatus: RiderAvailabilityStatus.available);
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

/// Grants location by default — the go-online flow this suite exercises
/// should succeed unless a test explicitly configures a denial, matching
/// how [FakeDashboardRepository] defaults to success unless a test sets an
/// error.
class FakeLocationPlatform implements LocationPlatform {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  int getCurrentPositionCalls = 0;

  Position _fixedPosition() => Position(
        latitude: 12.9716,
        longitude: 77.5946,
        timestamp: DateTime(2026, 1, 1),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({Duration? timeLimit}) async {
    getCurrentPositionCalls++;
    return _fixedPosition();
  }

  @override
  Stream<Position> getPositionStream({required int distanceFilterMeters}) =>
      const Stream<Position>.empty();

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<bool> openAppSettings() async => true;
}

class FakeLocationRepository implements LocationRepository {
  int sendPingCalls = 0;
  Object? sendPingError;

  @override
  Future<void> sendPing(RiderLocationPing ping) async {
    sendPingCalls++;
    if (sendPingError != null) throw sendPingError!;
  }
}

/// `DashboardHomeScreen` unconditionally watches `activeOrderProvider`, and
/// `RiderPollingController.start()` (kicked off from initState) awaits
/// `activeOrderProvider.future` directly during its cold-launch reconcile —
/// unlike `.valueOrNull`, `.future` rethrows a build failure instead of
/// swallowing it into an AsyncError. Without this override,
/// `ActiveOrderNotifier.build()` falls through to the real
/// `riderOrdersRepositoryProvider` → real `ApiClient`, which throws
/// (dotenv is never initialized in a widget test) as an unawaited async
/// error that flutter_test reports as a bare `NotInitializedError` failure
/// whenever a test happens to pump long enough for it to surface.
class FakeRiderOrdersRepository implements RiderOrdersRepository {
  @override
  Future<List<RiderOrderModel>> getCurrent() async => [];
  @override
  Future<RiderOrderModel> getOne(String riderOrderId) =>
      throw UnimplementedError();
  @override
  Future<OrderHistoryPageModel> getHistory({
    required OrderHistoryFilter filter,
    required int page,
    required int pageSize,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> markArrived(String riderOrderId) => throw UnimplementedError();
  @override
  Future<void> pickupSuccess(String riderOrderId) => throw UnimplementedError();
  @override
  Future<void> scanPickupQr(String riderOrderId, String token) =>
      throw UnimplementedError();
  @override
  Future<void> startDelivery(String riderOrderId) => throw UnimplementedError();
  @override
  Future<void> completeDelivery(String riderOrderId, String code) =>
      throw UnimplementedError();
  @override
  Future<void> cancel(String riderOrderId, String reason) =>
      throw UnimplementedError();
}

/// See the equivalent override in incoming_offer_screen_test.dart —
/// `DispatchOfferNotifier.build()` reads through this store (real impl:
/// `FlutterSecureStorage`, unavailable in widget tests) before ever reaching
/// the already-faked `dispatchRepositoryProvider`.
class FakeDispatchOfferStore implements DispatchOfferStore {
  @override
  Future<DispatchOfferModel?> read() async => null;
  @override
  Future<void> write(DispatchOfferModel offer) async {}
  @override
  Future<void> clear() async {}
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
  Future<String> accept(String attemptId) => throw UnimplementedError();

  @override
  Future<void> reject(String attemptId) => throw UnimplementedError();
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
  int onlineSecondsToday = 0,
}) =>
    DashboardStatsModel(
      riderName: 'Ravi Kumar',
      availabilityStatus: availabilityStatus,
      todaysEarningsPaise: 84200,
      todaysDeliveries: 14,
      walletBalancePaise: 312000,
      onlineSecondsToday: onlineSecondsToday,
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
  FakeProfileRepository? profileRepository,
  FakeLocationPlatform? locationPlatform,
  FakeLocationRepository? locationRepository,
}) {
  return ProviderScope(
    overrides: [
      dashboardRepositoryProvider.overrideWithValue(dashboardRepository),
      dispatchRepositoryProvider
          .overrideWithValue(dispatchRepository ?? FakeDispatchRepository()),
      dispatchOfferStoreProvider.overrideWithValue(FakeDispatchOfferStore()),
      riderOrdersRepositoryProvider.overrideWithValue(FakeRiderOrdersRepository()),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
      profileRepositoryProvider
          .overrideWithValue(profileRepository ?? FakeProfileRepository()),
      documentImagePickerProvider.overrideWithValue(FakeDocumentImagePicker()),
      locationPlatformProvider
          .overrideWithValue(locationPlatform ?? FakeLocationPlatform()),
      locationRepositoryProvider
          .overrideWithValue(locationRepository ?? FakeLocationRepository()),
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

    // The compact (<720px) dashboard body no longer renders any brand
    // wordmark/header at all (see DashboardHomeScreen.build — AppTabScaffold
    // only shows PartnerWordmark/"Qikzoo Partner" in its >=720px expanded
    // rail; the compact ListView goes straight into _HomeControlsRow), so
    // there's nothing literal to find here — dropped rather than pointed at
    // now-nonexistent UI. The assertions below are the real proof this
    // compact overview rendered.
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

  testWidgets(
      'shows the real backend-computed online time on the Today\'s progress card',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeDashboardRepository(
      initial: mockStats(
        availabilityStatus: RiderAvailabilityStatus.online,
        onlineSecondsToday: 8100, // 2h 15m
      ),
    );
    await tester.pumpWidget(buildApp(dashboardRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('2h 15m'), findsOneWidget);
    expect(find.text('0h 0m'), findsNothing);
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

  // A notification-bell test used to live here ("shows the unread
  // notification count and opens notifications"). DashboardHomeScreen no
  // longer references notificationsRepositoryProvider, NotificationModel, or
  // any bell/notifications UI at all (confirmed by grep — zero matches in
  // dashboard_home_screen.dart). The bell has moved towards the Profile tab
  // (ProfileHeader/PartnerProfileHeader in
  // lib/features/profile/widgets/profile_header.dart and
  // partner_profile_components.dart both now wrap PartnerNotificationButton),
  // but as of this audit neither of those header widgets is actually
  // instantiated anywhere in lib/ yet, and AppRoutes.notifications has no
  // reachable entry point — this is unfinished, pre-existing work from a
  // prior session (partner_profile_components.dart is one of the untouched,
  // already-modified files flagged at the start of this audit), not a
  // completed relocation. Rather than invent the missing wiring myself or
  // leave a test pointed at dead code, the obsolete test was removed here;
  // re-add equivalent coverage once the notification-bell relocation is
  // actually finished and wired to a real screen.

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
    // Confirming "Go online?" now pushes straight into
    // SelfieVerificationScreen(isOnlineCheck: true) — there is no separate
    // "Quick selfie check" sheet in between any more (see
    // DashboardHomeScreen._goOnline). Its CTA reads "Take selfie now" while
    // no photo is uploaded yet (SelfieVerificationScreen's PrimaryCtaButton
    // label).
    expect(find.text("Let's confirm it's you"), findsOneWidget);

    await tester.tap(find.text('Take selfie now'));
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
    // P0-1: a real GPS fix must be acquired and sent before the rider is
    // flipped to AVAILABLE — the transition that actually makes them
    // dispatch-eligible (see RiderAvailabilityService.transition —
    // AVAILABLE only mirrors into Redis GEO when a last-known position
    // already exists).
    expect(repo.goAvailableCalls, 1);
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
    await tester.tap(find.text('Take selfie now'));
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
    await tester.tap(find.text('Take selfie now'));
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
    await tester.tap(find.text('Take selfie now'));
    await pumpBounded(tester);
    await tapCaptureButton(tester);
    await tester.tap(find.text('Use Photo'));
    await pumpBounded(tester);

    expect(find.textContaining("You're offline"), findsNothing);
    expect(find.textContaining('Unable to connect'), findsOneWidget);
    // The toggle failed, so status stays exactly as it was — no data lost.
    // (No brand wordmark to check at compact width — see the earlier test's
    // comment on why the "Qikzoo" text assertion was dropped.)
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

    // Proof the retry actually loaded the dashboard (no brand wordmark
    // exists at this compact width to check instead — see above).
    expect(find.text('Could not load your dashboard'), findsNothing);
    expect(find.text('You are Offline'), findsOneWidget);
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

    // No brand wordmark to check at compact width (see above) — assert the
    // dashboard's own content rendered instead.
    expect(find.text('You are Offline'), findsOneWidget);
    expect(find.text('Incoming Offer Screen'), findsNothing);
  });

  // Resume-triggered dispatch-offer polling now lives in
  // RiderPollingController, driven by the app-root RiderPollingLifecycleObserver
  // (see app.dart) rather than this screen's own lifecycle observer — so it
  // works regardless of which tab is on screen, not just the Dashboard.
  // Covered by test/providers/polling/rider_polling_controller_test.dart and
  // test/shared/widgets/lifecycle/rider_polling_lifecycle_observer_test.dart.

  group('P0-1 location gating', () {
    testWidgets(
        'never calls goOnline when location services are off — shows a blocking dialog instead of the confirm dialog',
        (tester) async {
      setTallSurface(tester);
      final repo = FakeDashboardRepository(
        initial: mockStats(availabilityStatus: RiderAvailabilityStatus.offline),
      );
      final locationPlatform = FakeLocationPlatform()..serviceEnabled = false;
      await tester.pumpWidget(buildApp(
        dashboardRepository: repo,
        locationPlatform: locationPlatform,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('availability-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Turn on location'), findsOneWidget);
      // The rider never even sees the "Go online?" confirmation — location
      // is checked first, before anything else in the flow.
      expect(find.text('Go online?'), findsNothing);
      expect(repo.goOnlineCalls, 0);
      expect(find.text('You are Offline'), findsOneWidget);
    });

    testWidgets(
        'never calls goOnline when location permission is permanently denied',
        (tester) async {
      setTallSurface(tester);
      final repo = FakeDashboardRepository(
        initial: mockStats(availabilityStatus: RiderAvailabilityStatus.offline),
      );
      final locationPlatform = FakeLocationPlatform()
        ..permission = LocationPermission.deniedForever;
      await tester.pumpWidget(buildApp(
        dashboardRepository: repo,
        locationPlatform: locationPlatform,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('availability-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Location permission needed'), findsOneWidget);
      expect(find.text('Open app settings'), findsOneWidget);
      expect(repo.goOnlineCalls, 0);
      expect(find.text('You are Offline'), findsOneWidget);
    });

    testWidgets(
        'never calls goOnline when location permission is denied (recoverable)',
        (tester) async {
      setTallSurface(tester);
      final repo = FakeDashboardRepository(
        initial: mockStats(availabilityStatus: RiderAvailabilityStatus.offline),
      );
      final locationPlatform = FakeLocationPlatform()
        ..permission = LocationPermission.denied;
      await tester.pumpWidget(buildApp(
        dashboardRepository: repo,
        locationPlatform: locationPlatform,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('availability-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Location permission needed'), findsOneWidget);
      // No "Open Settings" action for a merely-denied (not permanently
      // denied) permission — the OS prompt itself is the recoverable path.
      expect(find.text('Open app settings'), findsNothing);
      expect(repo.goOnlineCalls, 0);
      expect(find.text('You are Offline'), findsOneWidget);
    });

    testWidgets(
        'rolls back to offline if goAvailable fails after goOnline already succeeded',
        (tester) async {
      setTallSurface(tester);
      final repo = FakeDashboardRepository(
        initial: mockStats(availabilityStatus: RiderAvailabilityStatus.offline),
      )..goAvailableError = const ApiException(message: 'Server error');
      final profileRepo = FakeProfileRepository();
      await tester.pumpWidget(buildApp(
        dashboardRepository: repo,
        profileRepository: profileRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('availability-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await pumpBounded(tester);
      await tester.tap(find.text('Take selfie now'));
      await pumpBounded(tester);
      await tapCaptureButton(tester);
      await tester.tap(find.text('Use Photo'));
      await pumpBounded(tester);

      expect(repo.goOnlineCalls, 1);
      expect(repo.goAvailableCalls, 1);
      // The rollback calls goOffline a second time (once for the failed
      // AVAILABLE attempt's cleanup) — the rider must never be left
      // ONLINE-but-not-AVAILABLE with no way back to a clean state.
      expect(repo.goOfflineCalls, 1);
      expect(find.text('You are Offline'), findsOneWidget);
    });
  });
}
