import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../../models/onboarding_status/onboarding_status_model.dart';
import '../../providers/core/api_providers.dart';

abstract class OnboardingStatusRepository {
  Future<OnboardingStatusModel> getStatus();
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
    final body = response.data;
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
