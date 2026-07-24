import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../../models/onboarding_status/onboarding_status_model.dart';
import '../../providers/core/api_providers.dart';

abstract class OnboardingStatusRepository {
  Future<OnboardingStatusModel> getStatus();

  /// `POST /rider/onboarding/submit` — idempotent; calling again after a
  /// successful submit just returns the current (already-SUBMITTED/
  /// UNDER_REVIEW) state rather than erroring. Returns nothing meaningful
  /// to route on: the endpoint responds with the raw `RiderOnboarding` row,
  /// not the computed [OnboardingStatusModel] shape (no `accountStatus`/
  /// `currentStep`/etc.) — callers must fetch [getStatus] again afterward
  /// for routing, same as every other section save in this app.
  Future<void> submitOnboarding({
    required String termsVersion,
    required String privacyPolicyVersion,
  });

  /// `POST /rider/onboarding/reapply` — only valid when
  /// `onboardingStatus == rejected && reapplyAllowed`; resets to
  /// IN_PROGRESS without wiping existing KYC/vehicle data. Same raw-row
  /// caveat as [submitOnboarding] — call [getStatus] again afterward.
  Future<void> reapply();
}

class MockOnboardingStatusRepository implements OnboardingStatusRepository {
  @override
  Future<OnboardingStatusModel> getStatus() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return const OnboardingStatusModel(
      accountStatus: RiderAccountStatus.active,
      onboardingStatus: RiderOnboardingStatus.approved,
    );
  }

  @override
  Future<void> submitOnboarding({
    required String termsVersion,
    required String privacyPolicyVersion,
  }) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
  }

  @override
  Future<void> reapply() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
  }
}

class DioOnboardingStatusRepository implements OnboardingStatusRepository {
  const DioOnboardingStatusRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<OnboardingStatusModel> getStatus() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.riderOnboarding,
    );
    return _parse(response.data);
  }

  @override
  Future<void> submitOnboarding({
    required String termsVersion,
    required String privacyPolicyVersion,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderOnboardingSubmit,
      data: {
        'acceptTerms': true,
        'acceptPrivacyPolicy': true,
        'termsVersion': termsVersion,
        'privacyPolicyVersion': privacyPolicyVersion,
      },
    );
  }

  @override
  Future<void> reapply() async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderOnboardingReapply,
    );
  }

  OnboardingStatusModel _parse(Map<String, dynamic>? body) {
    final nested = body?['data'];
    final payload = nested is Map<String, dynamic> ? nested : body;
    return OnboardingStatusModel.fromJson(payload ?? const {});
  }
}

final onboardingStatusRepositoryProvider =
    Provider<OnboardingStatusRepository>(
  (ref) => DioOnboardingStatusRepository(
    apiClient: ref.watch(apiClientProvider),
  ),
);
