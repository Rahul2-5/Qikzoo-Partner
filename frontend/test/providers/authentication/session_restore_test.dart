import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/api/dio_service.dart';
import 'package:delivery_partner_app/core/storage/secure_storage.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/authentication/session_restore_outcome.dart';
import 'package:delivery_partner_app/models/onboarding_status/onboarding_status_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/providers/authentication/auth_provider.dart';
import 'package:delivery_partner_app/providers/core/api_providers.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/onboarding_status/onboarding_status_repository.dart';
import 'package:delivery_partner_app/repositories/profile/profile_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(String body, int statusCode) => ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.profile, this.error});
  final PartnerProfileModel? profile;
  final Object? error;

  @override
  Future<PartnerProfileModel> getProfile() async {
    if (error != null) throw error!;
    return profile!;
  }

  @override
  Future<RatingModel> getRating() async =>
      const RatingModel(average: 0, totalRatings: 0);
}

class FakeOnboardingStatusRepository implements OnboardingStatusRepository {
  FakeOnboardingStatusRepository({this.status, this.error});
  final OnboardingStatusModel? status;
  final Object? error;

  @override
  Future<OnboardingStatusModel> getStatus() async {
    if (error != null) throw error!;
    return status!;
  }
}

class RecordingAuthRepository implements AuthRepository {
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

const activeStatus = OnboardingStatusModel(
  accountStatus: RiderAccountStatus.active,
  onboardingStatus: RiderOnboardingStatus.approved,
);

const pendingStatus = OnboardingStatusModel(
  accountStatus: RiderAccountStatus.pendingKyc,
  onboardingStatus: RiderOnboardingStatus.inProgress,
);

final testProfile = PartnerProfileModel(
  id: 'rider_1',
  name: 'Test Rider',
  phone: '9876543210',
  joinedDate: DateTime(2026, 1, 1),
);

ProviderContainer buildContainer({
  required FutureOr<ResponseBody> Function(RequestOptions options) refreshHandler,
  ProfileRepository? profileRepository,
  OnboardingStatusRepository? onboardingStatusRepository,
  AuthRepository? authRepository,
}) {
  final storage = SecureTokenStorage();
  final dioService = DioService(storage);
  dioService.dio.httpClientAdapter = FakeHttpClientAdapter(refreshHandler);

  final container = ProviderContainer(
    overrides: [
      secureTokenStorageProvider.overrideWithValue(storage),
      dioServiceProvider.overrideWithValue(dioService),
      if (profileRepository != null)
        profileRepositoryProvider.overrideWithValue(profileRepository),
      if (onboardingStatusRepository != null)
        onboardingStatusRepositoryProvider
            .overrideWithValue(onboardingStatusRepository),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
    ],
  );
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    dotenv.testLoad();
  });

  test('no stored refresh token restores to loggedOut without any network call', () async {
    var refreshCalled = false;
    final container = buildContainer(refreshHandler: (options) {
      refreshCalled = true;
      return jsonResponse('{}', 200);
    });
    addTearDown(container.dispose);

    final outcome =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(outcome, SessionRestoreOutcome.loggedOut);
    expect(refreshCalled, isFalse);
    expect(container.read(authSessionProvider).value, AuthSessionModel.empty);
  });

  test('valid refresh token + active account restores to active with the session populated',
      () async {
    final storage = SecureTokenStorage();
    await storage.saveTokens(accessToken: 'old', refreshToken: 'refresh-1');
    final dioService = DioService(storage);
    dioService.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      return jsonResponse('{"data":{"accessToken":"new-access","refreshToken":"new-refresh"}}', 200);
    });

    final container = ProviderContainer(overrides: [
      secureTokenStorageProvider.overrideWithValue(storage),
      dioServiceProvider.overrideWithValue(dioService),
      profileRepositoryProvider
          .overrideWithValue(FakeProfileRepository(profile: testProfile)),
      onboardingStatusRepositoryProvider
          .overrideWithValue(FakeOnboardingStatusRepository(status: activeStatus)),
    ]);
    addTearDown(container.dispose);

    final outcome =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(outcome, SessionRestoreOutcome.active);
    final session = container.read(authSessionProvider).value!;
    expect(session.isAuthenticated, isTrue);
    expect(session.partnerId, 'rider_1');
    expect(session.token, 'new-access');
  });

  test('valid refresh token + pending onboarding restores to needsOnboarding', () async {
    final storage = SecureTokenStorage();
    await storage.saveTokens(accessToken: 'old', refreshToken: 'refresh-1');
    final dioService = DioService(storage);
    dioService.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      return jsonResponse('{"data":{"accessToken":"new-access"}}', 200);
    });

    final container = ProviderContainer(overrides: [
      secureTokenStorageProvider.overrideWithValue(storage),
      dioServiceProvider.overrideWithValue(dioService),
      profileRepositoryProvider
          .overrideWithValue(FakeProfileRepository(profile: testProfile)),
      onboardingStatusRepositoryProvider
          .overrideWithValue(FakeOnboardingStatusRepository(status: pendingStatus)),
    ]);
    addTearDown(container.dispose);

    final outcome =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(outcome, SessionRestoreOutcome.needsOnboarding);
  });

  test('an expired/invalid refresh token restores to loggedOut and clears storage', () async {
    final storage = SecureTokenStorage();
    await storage.saveTokens(accessToken: 'old', refreshToken: 'bad-refresh');
    final dioService = DioService(storage);
    dioService.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      return jsonResponse('{"error":{"message":"invalid refresh token"}}', 401);
    });

    final container = ProviderContainer(overrides: [
      secureTokenStorageProvider.overrideWithValue(storage),
      dioServiceProvider.overrideWithValue(dioService),
    ]);
    addTearDown(container.dispose);

    final outcome =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(outcome, SessionRestoreOutcome.loggedOut);
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(container.read(authSessionProvider).value, AuthSessionModel.empty);
  });

  test('no internet during refresh restores to offline and preserves the stored session',
      () async {
    final storage = SecureTokenStorage();
    await storage.saveTokens(accessToken: 'old-access', refreshToken: 'refresh-1');
    final dioService = DioService(storage);
    dioService.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
    });

    final container = ProviderContainer(overrides: [
      secureTokenStorageProvider.overrideWithValue(storage),
      dioServiceProvider.overrideWithValue(dioService),
    ]);
    addTearDown(container.dispose);

    final outcome =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(outcome, SessionRestoreOutcome.offline);
    expect(await storage.getAccessToken(), 'old-access');
    expect(await storage.getRefreshToken(), 'refresh-1');
  });

  test('server unavailable during refresh restores to offline and preserves the stored session',
      () async {
    final storage = SecureTokenStorage();
    await storage.saveTokens(accessToken: 'old-access', refreshToken: 'refresh-1');
    final dioService = DioService(storage);
    dioService.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      return jsonResponse('{"error":{"message":"down"}}', 503);
    });

    final container = ProviderContainer(overrides: [
      secureTokenStorageProvider.overrideWithValue(storage),
      dioServiceProvider.overrideWithValue(dioService),
    ]);
    addTearDown(container.dispose);

    final outcome =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(outcome, SessionRestoreOutcome.offline);
    expect(await storage.getAccessToken(), 'old-access');
  });

  test('a 401 while fetching the profile after a successful refresh logs the rider out',
      () async {
    final storage = SecureTokenStorage();
    await storage.saveTokens(accessToken: 'old', refreshToken: 'refresh-1');
    final dioService = DioService(storage);
    dioService.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      return jsonResponse('{"data":{"accessToken":"new-access"}}', 200);
    });
    final authRepository = RecordingAuthRepository();

    final container = ProviderContainer(overrides: [
      secureTokenStorageProvider.overrideWithValue(storage),
      dioServiceProvider.overrideWithValue(dioService),
      profileRepositoryProvider.overrideWithValue(
        FakeProfileRepository(
          error: const ApiException(message: 'unauthorized', statusCode: 401),
        ),
      ),
      authRepositoryProvider.overrideWithValue(authRepository),
    ]);
    addTearDown(container.dispose);

    final outcome =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(outcome, SessionRestoreOutcome.loggedOut);
    expect(authRepository.loggedOut, isTrue);
  });

  test('a network failure while fetching the profile restores to offline, not loggedOut',
      () async {
    final storage = SecureTokenStorage();
    await storage.saveTokens(accessToken: 'old', refreshToken: 'refresh-1');
    final dioService = DioService(storage);
    dioService.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      return jsonResponse('{"data":{"accessToken":"new-access"}}', 200);
    });
    final authRepository = RecordingAuthRepository();

    final container = ProviderContainer(overrides: [
      secureTokenStorageProvider.overrideWithValue(storage),
      dioServiceProvider.overrideWithValue(dioService),
      profileRepositoryProvider.overrideWithValue(
        FakeProfileRepository(
          error: const ApiException(message: 'server down', statusCode: 503),
        ),
      ),
      authRepositoryProvider.overrideWithValue(authRepository),
    ]);
    addTearDown(container.dispose);

    final outcome =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(outcome, SessionRestoreOutcome.offline);
    expect(authRepository.loggedOut, isFalse);
    expect(await storage.getAccessToken(), 'new-access');
  });

  test('logout always clears the session even if server revocation fails', () async {
    final authRepository = RecordingAuthRepository();
    final container = buildContainer(
      refreshHandler: (options) => jsonResponse('{}', 200),
      authRepository: authRepository,
    );
    addTearDown(container.dispose);

    await container.read(authSessionProvider.notifier).logout();

    expect(authRepository.loggedOut, isTrue);
    expect(container.read(authSessionProvider).value, AuthSessionModel.empty);
  });
}
