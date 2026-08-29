import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/api/dio_service.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/core/storage/secure_storage.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/authentication/session_restore_outcome.dart';
import 'package:delivery_partner_app/models/onboarding_status/onboarding_status_model.dart';
import 'package:delivery_partner_app/models/partner_registration/personal_info_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/models/bank_details/bank_details_model.dart';
import 'package:delivery_partner_app/models/earnings/earnings_models.dart';
import 'package:delivery_partner_app/models/wallet/transaction_model.dart';
import 'package:delivery_partner_app/models/wallet/wallet_model.dart';
import 'package:delivery_partner_app/models/verification_status/verification_step_model.dart';
import 'package:delivery_partner_app/providers/authentication/auth_provider.dart';
import 'package:delivery_partner_app/providers/bank_details/bank_details_provider.dart';
import 'package:delivery_partner_app/providers/core/api_providers.dart';
import 'package:delivery_partner_app/providers/earnings/earnings_provider.dart';
import 'package:delivery_partner_app/providers/profile/profile_provider.dart';
import 'package:delivery_partner_app/providers/verification_status/verification_status_provider.dart';
import 'package:delivery_partner_app/providers/wallet/wallet_provider.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/bank_details/bank_details_repository.dart';
import 'package:delivery_partner_app/repositories/earnings/earnings_repository.dart';
import 'package:delivery_partner_app/repositories/onboarding_status/onboarding_status_repository.dart';
import 'package:delivery_partner_app/repositories/profile/profile_repository.dart';
import 'package:delivery_partner_app/repositories/verification_status/verification_status_repository.dart';
import 'package:delivery_partner_app/repositories/wallet/wallet_repository.dart';
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
  Future<PartnerProfileModel> uploadSelfie(
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

class FakeOnboardingStatusRepository implements OnboardingStatusRepository {
  FakeOnboardingStatusRepository({this.status, this.error});
  final OnboardingStatusModel? status;
  final Object? error;

  @override
  Future<OnboardingStatusModel> getStatus() async {
    if (error != null) throw error!;
    return status!;
  }

  @override
  Future<void> submitOnboarding({
    required String termsVersion,
    required String privacyPolicyVersion,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> reapply() => throw UnimplementedError();
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
  currentStep: 'REVIEW',
);

const pendingStatus = OnboardingStatusModel(
  accountStatus: RiderAccountStatus.pendingKyc,
  onboardingStatus: RiderOnboardingStatus.inProgress,
);

const pendingProfileStatus = OnboardingStatusModel(
  accountStatus: RiderAccountStatus.pendingKyc,
  onboardingStatus: RiderOnboardingStatus.inProgress,
  currentStep: 'PROFILE',
);

const pendingVehicleStatus = OnboardingStatusModel(
  accountStatus: RiderAccountStatus.pendingKyc,
  onboardingStatus: RiderOnboardingStatus.inProgress,
  currentStep: 'VEHICLE',
);

/// Counts fetches so a test can prove a provider was actually invalidated
/// (re-fetched) rather than serving a stale cached value.
class CountingWalletRepository implements WalletRepository {
  int walletCalls = 0;
  @override
  Future<WalletModel> getWallet() async {
    walletCalls++;
    return const WalletModel(balance: 100, pendingAmount: 0);
  }

  @override
  Future<List<TransactionModel>> getTransactions() async => const [];

  @override
  Future<CashDepositModel> createCashDeposit(int amountPaise) =>
      throw UnimplementedError();

  @override
  Future<CashDepositModel> getCashDeposit(String depositId) =>
      throw UnimplementedError();
}

class CountingEarningsRepository implements EarningsRepository {
  int summaryCalls = 0;
  @override
  Future<EarningsSummaryModel> getSummary() async {
    summaryCalls++;
    return EarningsSummaryModel.empty;
  }

  @override
  Future<EarningsHistoryPage> getHistory({int page = 1, int pageSize = 20}) async =>
      EarningsHistoryPage.empty;
}

class CountingBankDetailsRepository implements BankDetailsRepository {
  int getCalls = 0;
  @override
  Future<void> saveBankDetails(
    BankDetailsModel details, {
    required String accountNumber,
  }) =>
      throw UnimplementedError();
  @override
  Future<BankDetailsModel?> getBankDetails() async {
    getCalls++;
    return null;
  }
}

class CountingVerificationStatusRepository implements VerificationStatusRepository {
  int getCalls = 0;
  @override
  Future<List<VerificationStepModel>> getSteps() async {
    getCalls++;
    return const [];
  }
}

final testProfile = PartnerProfileModel(
  id: 'rider_1',
  publicRiderId: 'QRID00001',
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

    final result =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(result.outcome, SessionRestoreOutcome.loggedOut);
    expect(result.route, isNull);
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

    final result =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(result.outcome, SessionRestoreOutcome.active);
    expect(result.route, AppRoutes.dashboard,
        reason: 'active accounts always resolve to the dashboard, '
            'regardless of currentStep — same rule NextOnboardingStepResolver '
            'applies everywhere else');
    final session = container.read(authSessionProvider).value!;
    expect(session.isAuthenticated, isTrue);
    expect(session.partnerId, 'QRID00001');
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

    final result =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(result.outcome, SessionRestoreOutcome.needsOnboarding);
    expect(result.route, AppRoutes.verificationStatus,
        reason: 'no currentStep on this fixture — falls back to the status '
            'screen, same as NextOnboardingStepResolver would for any '
            'unbuilt/unknown step');
  });

  test(
      'pending onboarding with currentStep PROFILE resumes exactly on Personal Details — '
      'same NextOnboardingStepResolver every onboarding screen uses, no separate switch here',
      () async {
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
      onboardingStatusRepositoryProvider.overrideWithValue(
          FakeOnboardingStatusRepository(status: pendingProfileStatus)),
    ]);
    addTearDown(container.dispose);

    final result =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(result.outcome, SessionRestoreOutcome.needsOnboarding);
    expect(result.route, AppRoutes.personalInfo);
  });

  test(
      'pending onboarding with currentStep VEHICLE resumes exactly on Vehicle Registration',
      () async {
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
      onboardingStatusRepositoryProvider.overrideWithValue(
          FakeOnboardingStatusRepository(status: pendingVehicleStatus)),
    ]);
    addTearDown(container.dispose);

    final result =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(result.outcome, SessionRestoreOutcome.needsOnboarding);
    expect(result.route, AppRoutes.vehicleRegistration);
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

    final result =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(result.outcome, SessionRestoreOutcome.loggedOut);
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

    final result =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(result.outcome, SessionRestoreOutcome.offline);
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

    final result =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(result.outcome, SessionRestoreOutcome.offline);
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

    final result =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(result.outcome, SessionRestoreOutcome.loggedOut);
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

    final result =
        await container.read(authSessionProvider.notifier).restoreSession();

    expect(result.outcome, SessionRestoreOutcome.offline);
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

  // STEP 4 (Flutter release audit) — _invalidateSessionScopedState()
  // previously omitted profile/wallet/earnings/bank-details/verification
  // providers, so a rider logging out and a different rider logging in on
  // the same app process could see the PREVIOUS rider's cached name, wallet
  // balance, earnings, and bank details until a manual pull-to-refresh.
  // Proven here by reading each provider (forcing it into the cache), then
  // calling logout(), then reading again and confirming the underlying
  // repository was actually re-invoked rather than serving the cached value.
  test('logout invalidates profile/wallet/earnings/bank-details/verification providers',
      () async {
    final authRepository = RecordingAuthRepository();
    final wallet = CountingWalletRepository();
    final earnings = CountingEarningsRepository();
    final bankDetails = CountingBankDetailsRepository();
    final verification = CountingVerificationStatusRepository();

    final storage = SecureTokenStorage();
    final dioService = DioService(storage);
    dioService.dio.httpClientAdapter =
        FakeHttpClientAdapter((options) => jsonResponse('{}', 200));

    final container = ProviderContainer(overrides: [
      secureTokenStorageProvider.overrideWithValue(storage),
      dioServiceProvider.overrideWithValue(dioService),
      authRepositoryProvider.overrideWithValue(authRepository),
      profileRepositoryProvider
          .overrideWithValue(FakeProfileRepository(profile: testProfile)),
      walletRepositoryProvider.overrideWithValue(wallet),
      earningsRepositoryProvider.overrideWithValue(earnings),
      bankDetailsRepositoryProvider.overrideWithValue(bankDetails),
      verificationStatusRepositoryProvider.overrideWithValue(verification),
    ]);
    addTearDown(container.dispose);

    // Force every provider into the cache once, as if the rider had
    // actually opened the Profile/Wallet/Earnings screens.
    await container.read(profileProvider.future);
    await container.read(ratingProvider.future);
    await container.read(walletProvider.future);
    await container.read(earningsSummaryProvider.future);
    await container.read(bankDetailsProvider.future);
    await container.read(verificationStepsProvider.future);
    expect(wallet.walletCalls, 1);
    expect(earnings.summaryCalls, 1);
    expect(bankDetails.getCalls, 1);
    expect(verification.getCalls, 1);

    await container.read(authSessionProvider.notifier).logout();

    // Reading again after logout must trigger a genuine re-fetch, not
    // return the previous rider's cached value.
    await container.read(profileProvider.future);
    await container.read(walletProvider.future);
    await container.read(earningsSummaryProvider.future);
    await container.read(bankDetailsProvider.future);
    await container.read(verificationStepsProvider.future);
    expect(wallet.walletCalls, 2);
    expect(earnings.summaryCalls, 2);
    expect(bankDetails.getCalls, 2);
    expect(verification.getCalls, 2);
  });
}
